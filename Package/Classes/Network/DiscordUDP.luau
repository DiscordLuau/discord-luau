local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Signal = require("../../Vendor/Signal")
local Console = require("../../Vendor/Console")

local Net = require("../../Std/Net")
local Task = require("../../Std/Task")

--[=[
	@class Network.DiscordUDP

	DiscordUDP is an internal class responsible for managing UDP communication with the Discord API. This class handles sending and receiving UDP packets.

	:::caution
	This class is internal and should not be used directly by developers.
	:::
]=]
local DiscordUDP = {}

DiscordUDP.Interface = {}
DiscordUDP.Prototype = {}

DiscordUDP.Prototype.type = "DiscordUDP"

--[=[	
	Sends a UDP packet asynchronously.
	
	@private
	@method sendAsync
	@param dataPacket string -- The data packet to send.
	@within Network.DiscordUDP
	@return Future -- A Future that resolves when the packet is sent.
]=]
function DiscordUDP.Prototype.sendAsync(self: DiscordUDP, dataPacket: string)
	return Future.try(function()
		if not self.socketInstance then
			error(`Socket Instance isn't available!`)
		end

		self.socketInstance.send(dataPacket)
	end)
end

--[=[
	Connects to a UDP socket asynchronously.
	
	@private
	@method connectAsync
	@param discordUdp string -- The UDP address to connect to.
	@within Network.DiscordUDP
	@return Future -- A Future that resolves when the connection is established.
]=]
function DiscordUDP.Prototype.connectAsync(
	self: DiscordUDP,
	discordUdp: string
)
	return Future.try(function()
		local socket = self.socketInstance :: any

		self.socketUrl = discordUdp

		socket:connect(discordUdp)

		self.socketActive = true
		self.socketThread = Task.spawn(function()
			while self.socketActive do
				if not socket then
					return
				end

				if socket.closeCode then
					-- This isn't a thing, but in the real impl - it would be.
					self.socketActive = false

					self.onSocketDead:fire(socket.closeCode)
				else
					local socketMessage = socket.next()

					self.onMessageRecv:fire(buffer.tostring(socketMessage))
				end
			end
		end)
	end)
end

--[=[
	Disconnects from the UDP socket asynchronously.
	
	@private
	@method disconnectAsync
	@param closingCode string -- The closing code for the disconnection.
	@within Network.DiscordUDP
	@return Future -- A Future that resolves when the socket is disconnected.
]=]
function DiscordUDP.Prototype.disconnectAsync(self: DiscordUDP, closingCode: string)
	return Future.try(function()
		if not self.socketInstance then
			return
		end

		(Net :: any).udpSocketClose(self.socketInstance)
	end)
end

--[=[
	Creates a new instance of DiscordUDP.
	
	@function new
	@param publicUdp string -- The public UDP address.
	@within Network.DiscordUDP
	@return DiscordUDP -- A new instance of DiscordUDP.
]=]
function DiscordUDP.Interface.new(publicUdp: string)
	local self = Construct({
		publicUdp = publicUdp,
		socketInstance = (Net :: any).udpSocket(publicUdp),

		socketActive = false,
		socketActiveChanged = Signal.new(),

		onMessageRecv = Signal.new(),
		onSocketDead = Signal.new(),

		socketUrl = nil,

		reporter = Console.new("🪁 DiscordUDP"),
	}, DiscordUDP.Prototype)

	self.socketActiveChanged:connect(function(state)
		self.reporter:debug(`Discord UDP Socket {(state and "Connected") or "Disconnected"} [{self.socketUrl or "unknown"}]`)
	end)

	return self
end

export type DiscordUDP = typeof(DiscordUDP.Prototype) & {
	udpActive: boolean,
	publicUdp: string,

	onMessageRecv: Signal.Signal<string>,
	onSocketDead: Signal.Signal<number?>,

	socketInstance: Net.WebSocket?,

	reporter: Console.Console,

	socketUrl: string?,
	socketActive: boolean,
	socketActiveChanged: Signal.Signal<boolean>,

	socketThread: thread?
}

return DiscordUDP.Interface