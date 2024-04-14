local Future = require("../../Vendor/Future")
local Console = require("../../Vendor/Console")

local Construct = require("../../Utils/Construct")

local HTTPRatelimit = require("HTTPRatelimit")
local HTTPScheduler = require("HTTPScheduler")

local Serde = require("@lune/serde")
local Net = require("@lune/net")

local DISCORD_API_VERSION = 9

local BASE_DISCORD_APP_URL = "https://discord.com"
local BASE_DISCORD_APP_API_PREFIX = "api"

local DiscordGateway = {}

DiscordGateway.Type = "DiscordGateway"

DiscordGateway.Interface = {}
DiscordGateway.Prototype = {}

function DiscordGateway.Prototype.parseErrors(self: DiscordGateway, errorTable: { [string]: string }, source: string?, depth: number?)
	local _source = source or ""
	local _depth = depth or 0

	for index, value in errorTable do
		if index == "_errors" then
			for _, errorObject in value do
				_source ..= `{string.rep(" ", _depth)}{errorObject.code}: {errorObject.message}\n`
			end
		else
			_source ..= `{string.rep(" ", _depth)}{index}:\n{self:parseErrors(value, _source, _depth + 1)}\n`
		end
	end

	return _source
end

function DiscordGateway.Prototype.parseDiscordAPIErrors(self: DiscordGateway, api: string, networkResponse:{ body: string, statusCode: string, statusMessage: string })
	local success, messageDecoded = pcall(function()
		return Serde.decode("json", networkResponse.body)
	end)

	if success then
		local discordErrorString = self:parseErrors(messageDecoded.errors)

		return `Discord API Error - {messageDecoded.code} ({messageDecoded.message}): \n\nAPI: {api}\n\nTRACE:\n{discordErrorString}`
	end

	return `Discord HTTP Error - {networkResponse.statusCode} ({networkResponse.statusMessage}): \n{networkResponse.body}`
end

function DiscordGateway.Prototype.requestAsync(self: DiscordGateway, api: string, method: ("DELETE" | "GET" | "HEAD" | "OPTIONS" | "PATCH" | "POST" | "PUT"), data: { [any]: any })
	return Future.try(function()
		if self.EndpointRateLimits[api] and self.EndpointRateLimits[api]:isConsumed() then
			error(`HTTPRatelimit reached!`)
		end

		return self.DiscordScheduler:addTask(function()
			if self.EndpointRateLimits[api] and self.EndpointRateLimits[api]:isConsumed() then
				error(`HTTPRatelimit reached!`)
			end

			local networkResponse = Net.request({
				url = `{BASE_DISCORD_APP_URL}/{BASE_DISCORD_APP_API_PREFIX}/v{DISCORD_API_VERSION}/{api}`,
				method = method,
				headers = {
					["authorization"] = `Bot {self.DiscordClient.DiscordSettings.DiscordToken}`,
					["content-type"] = "application/json"
				},
				body = data and Serde.encode("json", data)
			})

			self.Reporter:debug(`{method} Async to '{api}': {networkResponse.statusCode} - {networkResponse.statusMessage}`)

			if not self.EndpointRateLimits[api] then
				self.EndpointRateLimits[api] = HTTPRatelimit.new(
					tonumber(networkResponse.headers["x-ratelimit-limit"]),
					tonumber(networkResponse.headers["x-ratelimit-remaining"])
				)
			end

			self.EndpointRateLimits[api]:resetAfter(tonumber(networkResponse.headers["x-ratelimit-reset-after"]))

			self.Reporter:debug(`{method} Rate Limit '{networkResponse.headers["x-ratelimit-limit"] - networkResponse.headers["x-ratelimit-remaining"]}/{networkResponse.headers["x-ratelimit-limit"]}, resetting in {networkResponse.headers["x-ratelimit-reset-after"]}'`)

			if not networkResponse.ok then
				error(self:parseDiscordAPIErrors(api, networkResponse))
			end

			if networkResponse.body == "" then
				return
			else
				return Serde.decode("json", networkResponse.body)
			end
		end)
	end)
end

function DiscordGateway.Prototype.getAsync(self: DiscordGateway, api, data)
	return Future.try(function()
		local cache = self:getEndpointCache(api)
		local cacheValue = cache and cache:get()

		if cacheValue then
			return cacheValue
		end

		local response = self:requestAsync(api, "GET", data):await()

		if cache then
			cache:set(response)
		end

		return response
	end)
end

function DiscordGateway.Prototype.postAsync(self: DiscordGateway, api: string, data: { [any]: any })
	return self:requestAsync(api, "POST", data)
end

function DiscordGateway.Prototype.deleteAsync(self: DiscordGateway, api: string, data: { [any]: any })
	return self:requestAsync(api, "DELETE", data)
end

function DiscordGateway.Prototype.patchAsync(self: DiscordGateway, api: string, data: { [any]: any })
	return self:requestAsync(api, "PATCH", data)
end

function DiscordGateway.Prototype.setEndpointCache(self: DiscordGateway, endpoint: string, cache: { [any]: any })
	self.EndpointCaches[endpoint] = cache
end

function DiscordGateway.Prototype.getEndpointCache(self: DiscordGateway, endpoint: string)
	return self.EndpointCaches[endpoint]
end

function DiscordGateway.Prototype.getApiVersion(self: DiscordGateway)
	return DISCORD_API_VERSION
end

function DiscordGateway.Interface.new(discordClient: any)
	return Construct({
		DiscordClient = discordClient,
		DiscordScheduler = HTTPScheduler.new(1),

		Reporter = Console.new("DiscordGateway"),

		EndpointRateLimits = {} :: { [string]: HTTPRatelimit.HTTPRatelimit },
		EndpointCaches = {} :: { [string]: { [any]: any } }
	}, DiscordGateway.Prototype)
end

export type DiscordGateway = typeof(DiscordGateway.Interface.new())

return DiscordGateway.Interface