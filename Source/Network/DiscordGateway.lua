local Promise = require("../Dependencies/Github/Promise")
local Console = require("../Dependencies/Github/Console")

local RateLimit = require("../Dependencies/RateLimit")
local Scheduler = require("../Dependencies/Scheduler")

local Serde = require("@lune/serde")
local Net = require("@lune/net")

local DISCORD_API_VERSION = 9

local BASE_DISCORD_APP_URL = "https://discord.com"
local BASE_DISCORD_APP_API_PREFIX = "api"

local DiscordGateway = {}

DiscordGateway.Type = "DiscordGateway"

DiscordGateway.Internal = {}
DiscordGateway.Interface = {}
DiscordGateway.Prototype = {
	Internal = DiscordGateway.Internal,
}

function DiscordGateway.Prototype:ToString()
	return `{DiscordGateway.Type}<"{self.WebsocketUri}">`
end

function DiscordGateway.Prototype:GetDiscordAppUri()
	return `{BASE_DISCORD_APP_URL}/{BASE_DISCORD_APP_API_PREFIX}`
end

function DiscordGateway.Prototype:RequestAsync(api, method, data)
	return Promise.new(function(resolve, reject)
		if self.EndpointRateLimits[api] and self.EndpointRateLimits[api]:IsConsumed() then
			return reject(`RateLimit reached!`)
		end

		self.Scheduler:AddTaskAsync(function()
			if self.EndpointRateLimits[api] and self.EndpointRateLimits[api]:IsConsumed() then
				return reject(`RateLimit reached!`)
			end

			local networkResponse = Net.request({
				url = `{BASE_DISCORD_APP_URL}/{BASE_DISCORD_APP_API_PREFIX}/v{DISCORD_API_VERSION}/{api}`,
				method = method,
				headers = {
					["authorization"] = `Bot {self.DiscordClient.DiscordToken}`,
					["content-type"] = "application/json"
				},
				body = data and Serde.encode("json", data)
			})

			self.Reporter:Debug(`{method} Async to '{api}': {networkResponse.statusCode} - {networkResponse.statusMessage}`)

			if not self.EndpointRateLimits[api] then
				self.EndpointRateLimits[api] = RateLimit.new()
			end

			self.EndpointRateLimits[api]:SetLimit(tonumber(networkResponse.headers["x-ratelimit-limit"]))
			self.EndpointRateLimits[api]:SetRemaining(tonumber(networkResponse.headers["x-ratelimit-remaining"]))
			self.EndpointRateLimits[api]:ResetAfter(tonumber(networkResponse.headers["x-ratelimit-reset-after"]))

			self.Reporter:Debug(`{method} Rate Limit '{networkResponse.headers["x-ratelimit-limit"] - networkResponse.headers["x-ratelimit-remaining"]}/{networkResponse.headers["x-ratelimit-limit"]}, resetting in {networkResponse.headers["x-ratelimit-reset-after"]}'`)

			if not networkResponse.ok then
				reject(
					`Failed to fetch discord gateway: {networkResponse.statusCode} - {networkResponse.statusMessage}`
				)
			end

			resolve(Serde.decode("json", networkResponse.body))
		end)
	end)
end

function DiscordGateway.Prototype:GetAsync(api, data)
	return Promise.new(function(resolve, reject)
		local cache = self:GetEndpointCache(api)
		local cacheValue = cache and cache:Get()

		if cacheValue then
			resolve(cacheValue)

			return
		end

		local success, response = self:RequestAsync(api, "GET", data):await()

		if success then
			if cache then
				cache:Set(response)
			end

			resolve(response)
		else
			reject(response)
		end
	end)
end

function DiscordGateway.Prototype:PostAsync(api, data)
	return self:RequestAsync(api, "POST", data)
end

function DiscordGateway.Prototype:SetEndpointCache(endpoint, cache)
	self.EndpointCaches[endpoint] = cache
end

function DiscordGateway.Prototype:GetEndpointCache(endpoint)
	return self.EndpointCaches[endpoint]
end

function DiscordGateway.Prototype:GetApiVersion()
	return DISCORD_API_VERSION
end

function DiscordGateway.Interface.new(discordClient)
	return setmetatable({
		DiscordClient = discordClient,
		Scheduler = Scheduler.new(1),

		Reporter = Console.new("DiscordGateway"),

		EndpointCaches = {},
		EndpointRateLimits = {}
	}, {
		__index = DiscordGateway.Prototype,
		__type = DiscordGateway.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordGateway.Interface
