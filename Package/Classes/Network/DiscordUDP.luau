local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Signal = require("../../Vendor/Signal")
local Console = require("../../Vendor/Console")
local State = require("../../Vendor/State")

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
		self.socketInstance:send(dataPacket)
	end)
end

function DiscordUDP.Prototype.connectAsync(
	self: DiscordUDP,
	discordUdp: string
)
	return Future.try(function()
		self.socketUrl = discordUdp
		self.socketInstance:connect(discordUdp)

		self.socketActive:set(true)
		self.socketThread = Task.spawn(function()
			while self.socketActive.Value do
				if self.socketInstance.closeCode then
					-- this isn't a thing, but in the real impl - it would be.
					self.socketActive:set(false)
					self.onSocketDead:fire(self.socketInstance.closeCode)
				else
					local socketMessage = self.socketInstance:next()

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

		socketActive = State.new(false),
		onMessageRecv = Signal.new(),
		onSocketDead = Signal.new(),
		onOperationRecv = Signal.new(),

		reporter = Console.new("🪁 DiscordUDP"),
	}, DiscordUDP.Prototype)

	self.socketActive.Changed:connect(function(state)
		self.reporter:debug(`Discord UDP Socket {(state and "Connected") or "Disconnected"} [{self.socketUrl or "unknown"}]`)
	end)

	return self
end

export type DiscordUDP = typeof(DiscordUDP.Prototype) & {
	udpActive: unknown,
	publicUdp: string,

	onMessageRecv: unknown,
	onSocketDead: unknown,

	reporter: unknown,
}

return DiscordUDP.Interface