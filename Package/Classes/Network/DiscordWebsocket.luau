local WebsocketOperationKeys = require("../../Enums/WebsocketOperationKeys")
local WebsocketOperationCodes = require("../../Enums/WebsocketOperationCodes")

local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Signal = require("../../Vendor/Signal")
local Console = require("../../Vendor/Console")
local State = require("../../Vendor/State")

local WebsocketBuffer = require("WebsocketBuffer")

local Net = require("@lune/net")
local Serde = require("@lune/serde")
local Task = require("@lune/task")

local ZLIB_SUFFIX_START = "\120"
local ZLIB_SUFFIX_END = "\84"

local DiscordWebsocket = {}

DiscordWebsocket.Type = "DiscordWebsocket"

DiscordWebsocket.Interface = {}
DiscordWebsocket.Prototype = {}

function DiscordWebsocket.Prototype.sendAsync(self: DiscordWebsocket, dataPacket)
	return Future.try(function()
		local messageSendOperationSuccessful, messageResult =
			pcall(self.SocketInstance.send, Serde.encode("json", dataPacket))

		if messageSendOperationSuccessful then
			self.Reporter:debug(`Discord Websocket Message Sent: {dataPacket[WebsocketOperationKeys.OperationCode]}`)

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

		self.WebsocketActive:set(true)
		self.WebsocketThread = Task.spawn(function()
			while self.WebsocketActive.Value do
				if self.SocketInstance.closeCode then
					self.WebsocketActive:set(false)
					self.OnSocketDead:fire(self.SocketInstance.closeCode)
				else
					local websocketMessage = self.SocketInstance.next()

					if not websocketMessage then
						self.WebsocketActive:set(false)
						self.OnSocketDead:fire(self.SocketInstance.closeCode)

						continue
					end

					self.OnMessageRecv:fire(websocketMessage)
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

		self.WebsocketActive:set(false)
		self.OnSocketDead:fire(closingCode)
	end)
end

function DiscordWebsocket.Interface.new(discordClient: any)
	local self = Construct({
		WebsocketActive = State.new(false),
		WebsocketWebsocketBuffer = WebsocketBuffer.new(),

		OnMessageRecv = Signal.new(),
		OnSocketDead = Signal.new(),
		OnOperationRecv = Signal.new(),

		Reporter = Console.new("DiscordWebsocket"),

		DiscordClient = discordClient,
	}, DiscordWebsocket.Prototype)

	self.WebsocketActive:observe(function(state)
		self.Reporter:debug(`Discord Websocket {(state and "Connected") or "Disconnected"}!`)
	end)

	self.OnMessageRecv:connect(function(discordPacket)
		local isJSON, dataPacket = pcall(function()
			return Serde.decode("json", discordPacket)
		end)

		if not isJSON then
			self.WebsocketWebsocketBuffer:add(discordPacket)

			if string.sub(discordPacket, 1, 1) ~= ZLIB_SUFFIX_START then
				return
			end

			if string.sub(discordPacket, 4, 4) ~= ZLIB_SUFFIX_END then
				return
			end

			local encodedDiscordPacket = self.WebsocketWebsocketBuffer:flush()
			local decodedDiscordPacket = Serde.decompress("zlib", encodedDiscordPacket)

			dataPacket = Serde.decode("json", decodedDiscordPacket)
		end

		if dataPacket[WebsocketOperationKeys.OperationCode] == WebsocketOperationCodes.Dispatch then
			self.Reporter:debug(`Discord Websocket Message Received: {dataPacket[WebsocketOperationKeys.OperationCode]} - {dataPacket[WebsocketOperationKeys.EventName]}`)
		else
			self.Reporter:debug(`Discord Websocket Message Received: {dataPacket[WebsocketOperationKeys.OperationCode]}`)
		end

		self.OnOperationRecv:fire(
			dataPacket[WebsocketOperationKeys.OperationCode],
			dataPacket[WebsocketOperationKeys.Data],
			dataPacket[WebsocketOperationKeys.EventName],
			dataPacket[WebsocketOperationKeys.Sequence]
		)
	end)

	return self
end

export type DiscordWebsocket = typeof(DiscordWebsocket.Interface.new())

return DiscordWebsocket.Interface