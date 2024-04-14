local WebsocketOperationKeys = require("../../Enums/WebsocketOperationKeys")
local WebsocketOperationCodes = require("../../Enums/WebsocketOperationCodes")

local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Signal = require("../../Vendor/Signal")
local Console = require("../../Vendor/Console")
local State = require("../../Vendor/State")

local EventIn = require("../Middleware/EventIn")
local EventOut = require("../Middleware/EventOut")

local WebsocketBuffer = require("WebsocketBuffer")

local Net = require("@lune/net")
local Serde = require("@lune/serde")
local Task = require("@lune/task")

local ZLIB_SUFFIX_START = "\120"
local ZLIB_SUFFIX_END = "\84"

local DiscordWebsocket = {}

DiscordWebsocket.Interface = {}
DiscordWebsocket.Prototype = {}

DiscordWebsocket.Prototype.type = "DiscordWebsocket"

function DiscordWebsocket.Prototype.sendAsync(self: DiscordWebsocket, dataPacket)
	return Future.try(function()
		local messageSendOperationSuccessful, messageResult =
			pcall(self.SocketInstance.send, Serde.encode("json", self.gatewayEventOut:processJSON(dataPacket)))

		if messageSendOperationSuccessful then
			self.reporter:debug(`Discord Websocket Message Sent: {dataPacket[WebsocketOperationKeys.OperationCode]}`)

			return
		else
			error(messageResult)
		end
	end)
end

function DiscordWebsocket.Prototype.connectAsync(self: DiscordWebsocket, websocketUrl)
	return Future.try(function()
		self.SocketRequestSuccess, self.SocketInstance = pcall(Net.socket, websocketUrl)

		if not self.SocketRequestSuccess then
			error(self.SocketInstance)
		end

		self.websocketActive:set(true)
		self.WebsocketThread = Task.spawn(function()
			while self.websocketActive.Value do
				if self.SocketInstance.closeCode then
					self.websocketActive:set(false)
					self.onSocketDead:fire(self.SocketInstance.closeCode)
				else
					local websocketMessage = self.SocketInstance.next()

					if not websocketMessage then
						self.websocketActive:set(false)
						self.onSocketDead:fire(self.SocketInstance.closeCode)

						continue
					end

					self.onMessageRecv:fire(websocketMessage)
				end
			end
		end)
	end)
end

function DiscordWebsocket.Prototype.disconnectAsync(self: DiscordWebsocket, closingCode: string)
	return Future.try(function()
		if not self.SocketInstance then
			return
		end

		self.SocketInstance.close(closingCode)

		self.websocketActive:set(false)
		self.onSocketDead:fire(closingCode)
	end)
end

function DiscordWebsocket.Interface.new()
	local self = Construct({
		websocketActive = State.new(false),
		websocketWebsocketBuffer = WebsocketBuffer.new(),

		gatewayEventIn = EventIn.new(),
		gatewayEventOut = EventOut.new(),

		onMessageRecv = Signal.new(),
		onSocketDead = Signal.new(),
		onOperationRecv = Signal.new(),

		reporter = Console.new("🪁 DiscordWebsocket"),
	}, DiscordWebsocket.Prototype)

	self.websocketActive:observe(function(state)
		self.reporter:debug(`Discord Websocket {(state and "Connected") or "Disconnected"}!`)
	end)

	self.onMessageRecv:connect(function(discordPacket)
		local isJSON, dataPacket = pcall(function()
			return Serde.decode("json", discordPacket)
		end)

		if not isJSON then
			self.websocketWebsocketBuffer:add(discordPacket)

			if string.sub(discordPacket, 1, 1) ~= ZLIB_SUFFIX_START then
				return
			end

			if string.sub(discordPacket, 4, 4) ~= ZLIB_SUFFIX_END then
				return
			end

			local encodedDiscordPacket = self.websocketWebsocketBuffer:flush()
			local decodedDiscordPacket = Serde.decompress("zlib", encodedDiscordPacket)

			dataPacket = Serde.decode("json", decodedDiscordPacket)
		end

		if dataPacket[WebsocketOperationKeys.OperationCode] == WebsocketOperationCodes.Dispatch then
			self.reporter:debug(`Discord Websocket Message Received: {dataPacket[WebsocketOperationKeys.OperationCode]} - {dataPacket[WebsocketOperationKeys.EventName]}`)
		else
			self.reporter:debug(`Discord Websocket Message Received: {dataPacket[WebsocketOperationKeys.OperationCode]}`)
		end

		self.onOperationRecv:fire(
			dataPacket[WebsocketOperationKeys.OperationCode],
			self.gatewayEventIn:processJSON(dataPacket[WebsocketOperationKeys.Data]),
			dataPacket[WebsocketOperationKeys.EventName],
			dataPacket[WebsocketOperationKeys.Sequence]
		)
	end)

	return self
end

export type DiscordWebsocket = typeof(DiscordWebsocket.Interface.new())

return DiscordWebsocket.Interface