local WebsocketOperationCodes = require("../Enums/WebsocketOperationCodes")
local WebsocketOperationKeys = require("../Enums/WebsocketOperationKeys")

local Observer = require("../Dependencies/Observer")
local Provider = require("../Dependencies/Provider")

local DiscordGateway = require("../Network/DiscordGateway")
local DiscordWebsocket = require("../Network/DiscordWebsocket")

local Promise = require("../Dependencies/Github/Promise")

local DiscordClient = {}

DiscordClient.Type = "DiscordClient"

DiscordClient.Internal = {}
DiscordClient.Interface = {}
DiscordClient.Prototype = {
	Internal = DiscordClient.Internal,
}

function DiscordClient.Prototype:ConnectAsync()
	return Promise.new(function(resolve, reject)
		self.Gateway = DiscordGateway.new()
		self.Websocket = DiscordWebsocket.new(self)

		self.Websocket
			:ConnectAsync()
			:andThen(function()
				self.Websocket.EventProvider:Subscribe(Observer.new("READY", function(dataPacket)
					self.Username = dataPacket.user.username
					self.Discriminator = dataPacket.user.discriminator

					self.Provider:InvokeObservers("OnReady")
				end))

				resolve()
			end)
			:catch(function(exception)
				reject(exception)
			end)
	end)
end

function DiscordClient.Prototype:UpdatePresenceAsync(discordPresence)
	return self.Websocket:SendAsync({
		[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.PresenseUpdate,
		[WebsocketOperationKeys.Data] = discordPresence:ToJSONObject(),
	})
end

function DiscordClient.Prototype:Subscribe(eventName, eventCallback)
	local observer = Observer.new(eventName, eventCallback)

	self.Provider:Subscribe(observer)

	return observer
end

function DiscordClient.Prototype:Unsubscribe(observer)
	self.Provider:Unsubscribe(observer)
end

function DiscordClient.Prototype:ToString()
	local safeDiscordToken = self.DiscordToken

	safeDiscordToken = string.sub(safeDiscordToken, 1, 40)
	safeDiscordToken ..= ` ...`

	return `{DiscordClient.Type}<"{safeDiscordToken}">`
end

function DiscordClient.Interface.new(discordClientSettings)
	assert(type(discordClientSettings.token) == "string", `Expected 'token' field in #1 'discordClientSettings'`)
	assert(type(discordClientSettings.intents) == "table", `Expected 'intents' field in #1 'discordClientSettings'`)

	return setmetatable({
		DiscordToken = discordClientSettings.token,
		DiscordIntents = table.clone(discordClientSettings.intents),

		Provider = Provider.new(),
	}, {
		__index = DiscordClient.Prototype,
		__type = DiscordClient.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordClient.Interface
