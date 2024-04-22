local Construct = require("../../Utils/Construct")

local Future = require("../../Vendor/Future")
local Signal = require("../../Vendor/Signal")
local Console = require("../../Vendor/Console")
local State = require("../../Vendor/State")

local Net = require("@lune/net")
local Task = require("@lune/task")
local FS = require("@lune/fs")

--[=[
	@class Internal.DiscordUDP

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordUDP = {}

DiscordUDP.Interface = {}
DiscordUDP.Prototype = {}

DiscordUDP.Prototype.type = "DiscordUDP"

function DiscordUDP.Prototype.sendAsync(self: DiscordUDP, dataPacket)
	return Future.try(function()
		
	end)
end

function DiscordUDP.Prototype.connectAsync(
	self: DiscordUDP,
	discordUdp: string
)
	return Future.try(function()
		self.socketUrl = discordUdp
		self.socketInstance:connect(discordUdp)
		print(discordUdp)

		self.socketActive:set(true)
		self.socketThread = Task.spawn(function()
			while self.socketActive.Value do
				if self.socketInstance.closeCode then
					self.socketActive:set(false)
					self.onSocketDead:fire(self.socketInstance.closeCode)
				else
					print("LISTENING!")
					local socketMessage = self.socketInstance:next()
					print("NEXT COMPLETED!")

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
	print("udp at: ", publicUdp)

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

	local i = 0

	self.onMessageRecv:connect(function(discordPacket)
		print(discordPacket)
		FS.writeFile("file-" .. tostring(i), discordPacket)

		i += 1
	end)

	return self
end

export type DiscordUDP = typeof(DiscordUDP.Prototype) & {
	udpActive: unknown,
	publicUdp: string,

	onMessageRecv: unknown,
	onSocketDead: unknown,
	onOperationRecv: unknown,

	reporter: unknown,
}

return DiscordUDP.Interface