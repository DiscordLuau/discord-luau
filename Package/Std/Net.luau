local net = require("@lune/net") :: any

--[[
	because 'udpSocket' is not actually apart of @lune/net, instead it was apart of a fork of @lune
		we don't want normal lune installs to error out - so I've implemented a generic/simple sandbox
		which simulates a 'udpSocket' but won't ever connect, send or recieve data.
]]

local udpSocket = net.udpSocket
local udpSocketClose = net.udpSocketClose

if not net.udpSocket then
	udpSocket = function()
		local self = {}

		self.send = function() end
		self.next = function() coroutine.yield() end
		self.connect = function() end

		return self
	end

	udpSocketClose = function() end
end

return setmetatable({
	udpSocket = udpSocket,
	udpSocketClose = udpSocketClose
}, {
	__index = require("@lune/net")
})