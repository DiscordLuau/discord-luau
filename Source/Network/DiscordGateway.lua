local Promise = require("../Dependencies/Github/Promise")

local Serde = require("@lune/serde")
local Net = require("@lune/net")

local DISCORD_API_VERSION = 10

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

function DiscordGateway.Prototype:RequestAsync(api, method)
	return Promise.new(function(resolve, reject)
		local networkResponse = Net.request({
			url = `{BASE_DISCORD_APP_URL}/{BASE_DISCORD_APP_API_PREFIX}/v{DISCORD_API_VERSION}/{api}`,
			method = method,
			headers = {
				["authorization"] = `Bot {self.DiscordClient.DiscordToken}`,
				["content-type"] = "application/json"
			}
		})

		if not networkResponse.ok then
			reject(
				`Failed to fetch discord gateway: {networkResponse.statusCode} - {networkResponse.statusMessage}`
			)
		end

		resolve(Serde.decode("json", networkResponse.body))
	end)
end

function DiscordGateway.Prototype:GetAsync(api)
	return Promise.new(function(resolve, reject)
		local cache = self:GetEndpointCache(api)
		local cacheValue = cache and cache:Get()

		if cacheValue then
			resolve(cacheValue)

			return
		end

		local success, response = self:RequestAsync(api, "GET"):await()

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

function DiscordGateway.Prototype:PostAsync(api)
	return self:RequestAsync(api, "POST")
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

		EndpointCaches = {}
	}, {
		__index = DiscordGateway.Prototype,
		__type = DiscordGateway.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordGateway.Interface
