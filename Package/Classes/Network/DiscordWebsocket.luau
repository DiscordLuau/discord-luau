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

--[=[
	@class Internal.DiscordWebsocket

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordWebsocket = {}

DiscordWebsocket.Interface = {}
DiscordWebsocket.Prototype = {}

DiscordWebsocket.Prototype.type = "DiscordWebsocket"

function DiscordWebsocket.Prototype.sendAsync(self: DiscordWebsocket, dataPacket)
	return Future.try(function()
		local messageSendOperationSuccessful, messageResult =
			pcall(self.socketInstance.send, Serde.encode("json", self.gatewayEventOut:processJSON(dataPacket)))

		if messageSendOperationSuccessful then
			self.reporter:debug(`Discord Websocket Message Sent: {dataPacket[WebsocketOperationKeys.OperationCode]}`)

			return
		else
			error(messageResult)
		end
	end)
end

function DiscordWebsocket.Prototype.connectAsync(self: DiscordWebsocket, websocketUrl: string)
	return Future.try(function()
		self.socketUrl = websocketUrl
		self.socketRequestSuccess, self.socketInstance = pcall(Net.socket, websocketUrl)

		if not self.socketRequestSuccess then
			error(self.socketInstance)
		end

		self.socketActive:set(true)
		self.socketThread = Task.spawn(function()
			while self.socketActive.Value do
				if self.socketInstance.closeCode then
					self.socketActive:set(false)
					self.onSocketDead:fire(self.socketInstance.closeCode)
				else
					local socketMessage = self.socketInstance.next()

					if not socketMessage then
						self.socketActive:set(false)
						self.onSocketDead:fire(self.socketInstance.closeCode)

						continue
					end

					self.onMessageRecv:fire(socketMessage)
				end
			end
		end)
	end)
end

function DiscordWebsocket.Prototype.disconnectAsync(self: DiscordWebsocket, closingCode: string)
	return Future.try(function()
		if not self.socketInstance then
			return
		end

		self.socketInstance.send(`{closingCode}`)
		self.socketInstance.close(closingCode)

		self.socketActive:set(false)
		self.onSocketDead:fire(closingCode)
	end)
end

function DiscordWebsocket.Interface.new()
	local self = Construct({
		socketActive = State.new(false),
		websocketWebsocketBuffer = WebsocketBuffer.new(),

		gatewayEventIn = EventIn.new(),
		gatewayEventOut = EventOut.new(),

		onMessageRecv = Signal.new(),
		onSocketDead = Signal.new(),
		onOperationRecv = Signal.new(),

		reporter = Console.new("🪁 DiscordWebsocket"),
	}, DiscordWebsocket.Prototype)

	self.socketActive:observe(function(state)
		self.reporter:debug(`Discord Websocket {(state and "Connected") or "Disconnected"} [{self.socketUrl or "unknown"}]`)
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

export type DiscordWebsocket = typeof(DiscordWebsocket.Prototype) & {
	socketActive: unknown,
	websocketWebsocketBuffer: WebsocketBuffer.WebsocketBuffer,

	gatewayEventIn: EventIn.EventIn,
	gatewayEventOut: EventOut.EventOut,

	onMessageRecv: unknown,
	onSocketDead: unknown,
	onOperationRecv: unknown,

	reporter: unknown,
}

return DiscordWebsocket.Interface