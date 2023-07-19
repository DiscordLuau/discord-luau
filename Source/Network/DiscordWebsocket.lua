local WebsocketOperationCodes = require("../Enums/WebsocketOperationCodes")
local WebsocketOperationKeys = require("../Enums/WebsocketOperationKeys")

local Promise = require("../Dependencies/Github/Promise")
local Event = require("../Dependencies/Event")

local Observer = require("../Dependencies/Observer")
local Provider = require("../Dependencies/Provider")
local Buffer = require("../Dependencies/Buffer")

local Net = require("@lune/net")
local Serde = require("@lune/serde")
local Process = require("@lune/process")
local Task = require("@lune/task")

local ZLIB_SUFFIX = "\120\156\133\84"

local DiscordWebsocket = {}

DiscordWebsocket.Type = "DiscordWebsocket"

DiscordWebsocket.Internal = {}
DiscordWebsocket.Prototype = {
	Internal = DiscordWebsocket.Internal,
}
DiscordWebsocket.Interface = {
	Internal = DiscordWebsocket.Internal,
}

function DiscordWebsocket.Prototype:CreateEventObservers()
	self.EventProvider:Subscribe(Observer.new("READY", function(dataPacket)
		self.WebsocketSessionId = dataPacket.session_id
		self.WebsocketResumeGatewayUrl = dataPacket.resume_gateway_url
	end))
end

function DiscordWebsocket.Prototype:CreateOperationalObservers()
	self.OperationProvider:Subscribe(Observer.new("ClientReconnectAsync", function()
		self:CancelHeartbeat()
		self:DisconnectAsync(1005):andThen(function()
			self:ConnectAsync(true)
		end)
	end))

	self.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.Dispatch, function(eventName, dataPacket)
		self.EventProvider:InvokeObservers(eventName, dataPacket)
	end))

	self.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.Heartbeat, function()
		self:HeartbeatAsync()
	end))

	self.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.Reconnect, function()
		self.OperationProvider:InvokeObservers("ClientReconnectAsync")
	end))

	self.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.InvalidSession, function(_, dataPacket)
		if dataPacket then
			self.OperationProvider:InvokeObservers("ClientReconnectAsync")
		else
			error(`Discord session was invalidated, please ensure that the bot's permissions & token is correct!`)
		end
	end))

	self.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.Hello, function(_, dataPacket)
		self.WebsocketHeartbeat = (dataPacket.heartbeat_interval / 1000) - 5

		self:CancelHeartbeat()
		self:StartHeartbeat()
	end))

	self.OperationProvider:Subscribe(Observer.new(WebsocketOperationCodes.HeartbeatACK, function()
		self.WebsocketHeartbeatACK = true
	end))
end

function DiscordWebsocket.Prototype:HeartbeatAsync()
	return self:SendAsync({
		[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Heartbeat,
		[WebsocketOperationKeys.Data] = self.WebsocketMessageSequence,
	}):andThen(function(...)
		self:IdentifyAsync()

		return ...
	end)
end

function DiscordWebsocket.Prototype:CancelHeartbeat()
	if not self.HeartbeatThread then
		return
	end

	Task.cancel(self.HeartbeatThread)
end

function DiscordWebsocket.Prototype:StartHeartbeat()
	self.HeartbeatThread = Task.spawn(function()
		Task.wait(math.random())

		self:HeartbeatAsync():await()

		while true do
			Task.wait(self.WebsocketHeartbeat)

			if not self.WebsocketHeartbeatACK then
				return self.OperationProvider:InvokeObservers("ClientReconnectAsync")
			end

			self.WebsocketHeartbeatACK = nil
			self:HeartbeatAsync():await()
		end
	end)
end

function DiscordWebsocket.Prototype:SendAsync(dataPacket)
	return Promise.new(function(resolve, reject)
		local messageSendOperationSuccessful, messageResult =
			true, self.SocketInstance.send(Serde.encode("json", dataPacket))

		if messageSendOperationSuccessful then
			resolve()
		else
			reject(messageResult)
		end
	end)
end

function DiscordWebsocket.Prototype:IdentifyAsync()
	return Promise.new(function(resolve, reject)
		if self.ClientIdentified then
			return resolve()
		else
			self.ClientIdentified = true
		end

		-- // TO-DO: Implement the following settings:
		-- sharding

		self:SendAsync({
			[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Identify,
			[WebsocketOperationKeys.Data] = {
				["token"] = self.DiscordClient.DiscordToken,
				["intents"] = self.DiscordClient.DiscordIntents:ToJSONObject(),
				["properties"] = {
					["os"] = Process.os,
					["browser"] = "DiscordLuaU",
					["device"] = "DiscordLuaU",
				},
				["compress"] = true,
				["large_threshold"] = 250,
				["shard"] = { 0, 1 },
			},
		})
			:andThen(function()
				resolve()
			end)
			:catch(function(exception)
				self.ClientIdentified = false

				reject(exception)
			end)
	end)
end

function DiscordWebsocket.Prototype:ConnectAsync(resumePreviousSession)
	return Promise.new(function(resolve, reject)
		self.DiscordClient.Gateway
			:GetWebsocketUriAsync()
			:andThen(function(wssUri)
				self.SocketRequestSuccess, self.SocketInstance =
					pcall(Net.socket, self.WebsocketResumeGatewayUrl or wssUri)

				if not self.SocketRequestSuccess then
					reject(self.SocketInstance)
				end

				if resumePreviousSession then
					local success, response = self:SendAsync({
						[WebsocketOperationKeys.OperationCode] = WebsocketOperationCodes.Resume,
						[WebsocketOperationKeys.Data] = {
							["token"] = self.DiscordClient.DiscordToken,
							["session_id"] = self.WebsocketSessionId,
							["seq"] = self.WebsocketMessageSequence,
						},
					}):await()

					if not success then
						reject(response)
					end
				end

				self.WebsocketActive = true
				self.WebsocketThread = Task.spawn(function()
					resolve()

					while self.WebsocketActive do
						Task.wait(1)

						if self.SocketInstance.closeCode then
							self.WebsocketActive = false
							self.OnSocketDead:Invoke(self.SocketInstance.closeCode)
						else
							local websocketMessage = self.SocketInstance.next()

							if not websocketMessage then
								self.WebsocketActive = false
								self.OnSocketDead:Invoke(self.SocketInstance.closeCode)
							end

							self.OnMessageRecv:Invoke(websocketMessage)
						end
					end
				end)
			end)
			:catch(function(exception)
				reject(exception)
			end)
	end)
end

function DiscordWebsocket.Prototype:DisconnectAsync(closingCode)
	return Promise.new(function(resolve)
		if not self.SocketInstance then
			return resolve()
		end

		Task.spawn(self.SocketInstance.close, closingCode)

		self.WebsocketActive = false
		self.OnSocketDead:Invoke(closingCode)

		resolve()
	end)
end

function DiscordWebsocket.Prototype:ToString()
	return `{DiscordWebsocket.Type}<"{self.WebsocketActive and "ONLINE" or "OFFLINE"}">`
end

function DiscordWebsocket.Interface.new(discordClient)
	local websocket = setmetatable({
		WebsocketActive = false,
		WebsocketBuffer = Buffer.new(),

		OnMessageRecv = Event.new(),
		OnSocketDead = Event.new(),

		OperationProvider = Provider.new(),
		EventProvider = Provider.new(),

		DiscordClient = discordClient,
	}, {
		__index = DiscordWebsocket.Prototype,
		__type = DiscordWebsocket.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})

	websocket.OnSocketDead:Connect(function()
		print("Websocket has died with error code:", websocket.SocketInstance.closeCode)
	end)

	websocket.OnMessageRecv:Connect(function(discordPacket)
		local isJSON, dataPacket = pcall(Serde.decode, "json", discordPacket)

		if not isJSON then
			websocket.WebsocketBuffer:Add(discordPacket)

			if string.sub(discordPacket, 1, 4) ~= ZLIB_SUFFIX then
				return
			end

			local encodedDiscordPacket = websocket.WebsocketBuffer:Flush()
			local decodedDiscordPacket = Serde.decompress("zlib", encodedDiscordPacket)

			dataPacket = Serde.decode("json", decodedDiscordPacket)
		end

		websocket.WebsocketMessageSequence = dataPacket[WebsocketOperationKeys.Sequence]
		websocket.OperationProvider:InvokeObservers(
			dataPacket[WebsocketOperationKeys.OperationCode],
			dataPacket[WebsocketOperationKeys.EventName],
			dataPacket[WebsocketOperationKeys.Data]
		)
	end)

	websocket:CreateEventObservers()
	websocket:CreateOperationalObservers()

	return websocket
end

return DiscordWebsocket.Interface
