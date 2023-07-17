local Promise = require("../Dependencies/Github/Promise")
local Net = require("@lune/net")

local BASE_DISCORD_APP_URL = "https://discordapp.com"
local BASE_DISCORD_APP_API_PREFIX = "api"

local DiscordGateway = {}

DiscordGateway.Type = "DiscordGateway"

DiscordGateway.Internal = {}
DiscordGateway.Prototype = {
	Internal = DiscordGateway.Internal,
}
DiscordGateway.Interface = {
	Internal = DiscordGateway.Internal,
}

function DiscordGateway.Prototype:ToString()
	return `{DiscordGateway.Type}<"{self.WebsocketUri}">`
end

function DiscordGateway.Prototype:GetDiscordAppUri()
	return `{BASE_DISCORD_APP_URL}/{BASE_DISCORD_APP_API_PREFIX}`
end

function DiscordGateway.Prototype:GetWebsocketUriAsync()
	return Promise.new(function(resolve, reject)
		if self.WebsocketUri then
			return resolve(self.WebsocketUri)
		else
			local networkResponse = Net.request({
				url = `{BASE_DISCORD_APP_URL}/{BASE_DISCORD_APP_API_PREFIX}/gateway`,
				method = "GET",
			})

			if not networkResponse.ok then
				reject(
					`Failed to fetch discord gateway: {networkResponse.statusCode} - {networkResponse.statusMessage}`
				)
			end

			self.WebsocketUri = Net.jsonDecode(networkResponse.body).url

			resolve(self.WebsocketUri)
		end
	end)
end

function DiscordGateway.Interface.new(websocketUri)
	return setmetatable({
		WebsocketUri = websocketUri,
	}, {
		__index = DiscordGateway.Prototype,
		__type = DiscordGateway.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordGateway.Interface
