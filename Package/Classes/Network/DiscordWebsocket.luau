local WebsocketOperationKeys = require("../../Enums/WebsocketOperationKeys")
local WebsocketOperationCodes = require("../../Enums/WebsocketOperationCodes")

local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Signal = require("../../Vendor/Signal")
local Console = require("../../Vendor/Console")

local EventIn = require("Middleware/EventIn")
local EventOut = require("Middleware/EventOut")

local WebsocketBuffer = require("WebsocketBuffer")

local Net = require("../../Std/Net")
local Serde = require("../../Std/Serde")
local Task = require("../../Std/Task")

local ZLIB_SUFFIX_START = "\120"
local ZLIB_SUFFIX_END = "\84"

--[=[
	@class Network.DiscordWebsocket

	The `DiscordWebsocket` class manages the websocket connection to Discord. It handles sending and receiving messages, managing the connection state, and processing incoming and outgoing events.

	:::caution
	This class is internal and should not be used directly by developers. Instead, use the provided public interfaces and methods to interact with the Discord websocket.
	:::
]=]
local DiscordWebsocket = {}

DiscordWebsocket.Interface = {}
DiscordWebsocket.Prototype = {}

DiscordWebsocket.Prototype.type = "DiscordWebsocket"

--[=[
	Sends a data packet asynchronously through the websocket.
	
	@private
	@method sendAsync
	@param self DiscordWebsocket
	@param dataPacket table -- The data packet to send.
	@within Network.DiscordWebsocket
	@return Future
]=]
function DiscordWebsocket.Prototype.sendAsync(self: DiscordWebsocket, dataPacket: { [any]: any })
	local traceback = debug.traceback()

	return Future.try(function()
		if not self.socketInstance then
			error(`No WebSocket available!`)
		end

		local messageSendOperationSuccessful, result = pcall(function()
			return (
				self.socketInstance.send(Serde.encode("json", self.gatewayEventOut:processJSON(dataPacket))) :: unknown
			) :: buffer
		end)

		if messageSendOperationSuccessful then
			self.reporter:debug(`Discord Websocket Message Sent: {dataPacket[WebsocketOperationKeys.OperationCode]}`)
		else
			local resultType: string = typeof(result)
			local messageResult

			if resultType == "userdata" then
				local success = pcall(function()
					messageResult = buffer.tostring(result)
				end)

				if not success then
					messageResult = tostring(result)
				end
			end

			self.reporter:warn(`Socket error: {string.split(messageResult, "\n")[1]}, traceback:\n{traceback}`)

			self.socketActive = false
			self.onSocketDead:fire(self.socketInstance.closeCode)
		end
	end)
end

--[=[
	Connects to a websocket URL asynchronously.
	
	@private
	@method connectAsync
	@param self DiscordWebsocket
	@param websocketUrl string -- The URL to connect to.
	@within Network.DiscordWebsocket
	@return Future
]=]
function DiscordWebsocket.Prototype.connectAsync(self: DiscordWebsocket, websocketUrl: string)
	return Future.try(function()
		self.socketUrl = websocketUrl
		self.socketRequestSuccess, self.socketInstance = pcall(Net.socket, websocketUrl)

		if not self.socketRequestSuccess then
			error(self.socketInstance)
		end

		self.socketActive = true
		self.socketThread = Task.spawn(function()
			while self.socketActive do
				if not self.socketInstance then
					return
				end

				if self.socketInstance.closeCode then
					self.socketActive = false
					self.onSocketDead:fire(self.socketInstance.closeCode)
				else
					local success, socketMessage = pcall(self.socketInstance.next)

					if not success or not socketMessage then
						self.socketActive = false
						self.onSocketDead:fire(self.socketInstance.closeCode)

						continue
					end

					self.onMessageRecv:fire(socketMessage)
				end
			end
		end)
	end)
end

--[=[
	Disconnects from the websocket asynchronously.
	
	@private
	@method disconnectAsync
	@param self DiscordWebsocket
	@param closingCode string -- The closing code for the disconnection.
	@within Network.DiscordWebsocket
	@return Future
]=]
function DiscordWebsocket.Prototype.disconnectAsync(self: DiscordWebsocket, closingCode: string)
	return Future.try(function()
		if not self.socketInstance then
			return
		end

		if self.socketActive then
			xpcall(function()
				self.socketInstance.close(tonumber(closingCode))
			end, function(source: string)
				self.reporter:warn(`Failed to close websocket: '{source}'`)
			end)
		end

		self.socketActive = false
		self.onSocketDead:fire(tonumber(closingCode))
	end)
end

--[=[
	Creates a new instance of `DiscordWebsocket`.
	
	@private
	@method new
	@return DiscordWebsocket
	@within Network.DiscordWebsocket
]=]
function DiscordWebsocket.Interface.new()
	local self = Construct({
		websocketWebsocketBuffer = WebsocketBuffer.new(),

		gatewayEventIn = EventIn.new(),
		gatewayEventOut = EventOut.new(),

		onMessageRecv = Signal.new(),
		onSocketDead = Signal.new(),
		onOperationRecv = Signal.new(),

		reporter = Console.new("🪁 DiscordWebsocket"),

		socketActiveChanged = Signal.new(),
		socketActive = false,

		socketUrl = nil,
		socketInstance = nil,

		socketRequestSuccess = nil,
		socketThread = nil,
	}, DiscordWebsocket.Prototype)

	self.socketActiveChanged:connect(function(state)
		local connectedLabel = state and "Connected" or "Disconnected"

		local socketUrl = self.socketUrl and `[{self.socketUrl}]` or ""
		local closeCode = self.socketInstance and self.socketInstance.closeCode and `[{self.socketInstance.closeCode}]`
			or ""

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
			self.reporter:debug(
				`Discord Websocket Message Received: {dataPacket[WebsocketOperationKeys.OperationCode]} - {dataPacket[WebsocketOperationKeys.EventName]}`
			)
		else
			self.reporter:debug(
				`Discord Websocket Message Received: {dataPacket[WebsocketOperationKeys.OperationCode]}`
			)
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
	websocketWebsocketBuffer: WebsocketBuffer.WebsocketBuffer,

	socketActiveChanged: Signal.Signal<boolean>,
	socketActive: boolean,

	gatewayEventIn: EventIn.EventIn,
	gatewayEventOut: EventOut.EventOut,

	onMessageRecv: Signal.Signal<string>,
	onSocketDead: Signal.Signal<number?>,
	onOperationRecv: Signal.Signal<number, any, string?, number?>,

	reporter: Console.Console,

	socketUrl: string?,
	socketInstance: Net.WebSocket?,

	socketRequestSuccess: boolean?,
	socketThread: thread?,
}

return DiscordWebsocket.Interface
