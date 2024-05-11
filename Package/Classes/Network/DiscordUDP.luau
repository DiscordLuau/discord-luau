local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Signal = require("../../Vendor/Signal")
local Console = require("../../Vendor/Console")

local Net = require("../../Std/Net")
local Task = require("../../Std/Task")

--[=[
	@class Network.DiscordUDP

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordUDP = {}

DiscordUDP.Interface = {}
DiscordUDP.Prototype = {}

DiscordUDP.Prototype.type = "DiscordUDP"

function DiscordUDP.Prototype.sendAsync(self: DiscordUDP, dataPacket: string)
	return Future.try(function()
		if not self.socketInstance then
			error(`Socket Instance isn't avaliable!`)
		end

		self.socketInstance.send(dataPacket)
	end)
end

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
					-- this isn't a thing, but in the real impl - it would be.
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

function DiscordUDP.Prototype.disconnectAsync(self: DiscordUDP, closingCode: string)
	return Future.try(function()
		if not self.socketInstance then
			return
		end

		(Net :: any).udpSocketClose(self.socketInstance)
	end)
end

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