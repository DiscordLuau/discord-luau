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

local Net = require("../../Std/Net")
local Serde = require("../../Std/Serde")
local Task = require("../../Std/Task")

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
	local traceback = debug.traceback()

	return Future.try(function()
		local messageSendOperationSuccessful, messageResult =
			pcall(self.socketInstance.send, Serde.encode("json", self.gatewayEventOut:processJSON(dataPacket)))

		if messageSendOperationSuccessful then
			self.reporter:debug(`Discord Websocket Message Sent: {dataPacket[WebsocketOperationKeys.OperationCode]}`)
		else
			local resultType = typeof(messageResult)

			if resultType == "userdata" then
				local success = pcall(function()
					messageResult = buffer.tostring(messageResult)
				end)

				if not success then
					messageResult = tostring(messageResult)
				end
			end

			self.reporter:warn(`Socket error: {string.split(messageResult, "\n")[1]}, traceback:\n{traceback}`)

			self.socketActive:set(false)
			self.onSocketDead:fire(self.socketInstance.closeCode)
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
					local success, socketMessage = pcall(self.socketInstance.next)

					if not success or not socketMessage then
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

		if self.socketActive.Value then
			xpcall(function()
				self.socketInstance.close(closingCode)
			end, function(source: string)
				self.reporter:warn(`Failed to close websocket: '{source}'`)
			end)
		end

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

	self.socketActive.Changed:connect(function(state)
		local connectedLabel = state and "Connected" or "Disconnected"
		local socketUrl = self.socketUrl and `[{self.socketUrl}]` or ""
		local closeCode = self.socketInstance and self.socketInstance.closeCode and `[{self.socketInstance.closeCode}]` or ""

		self.reporter:debug(`Discord Websocket {connectedLabel} {socketUrl} {closeCode}`)
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