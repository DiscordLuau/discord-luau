--[[
	Imports a Standard runtime library, in this case we're using Lune - but if we wanted to hop into another Runtime..
		theoretically, we could - we'd just need to emulate the lune runtime.
]]

local net = require("@lune/net")

--[[
	because 'udpSocket' is not actually apart of @lune/net, instead it was apart of a fork of @lune
		we don't want normal lune installs to error out - so I've implemented a generic/simple sandbox
		which simulates a 'udpSocket' but won't ever connect, send or recieve data.
]]

local udpSocket = (net :: any).udpSocket
local udpSocketClose = (net :: any).udpSocketClose

if not (net :: any).udpSocket then
	udpSocket = function()
		local self = {}

		self.send = function() end
		self.next = function()
			coroutine.yield()
		end
		self.connect = function() end

		return self
	end

	udpSocketClose = function() end
end

export type WebSocket = net.WebSocket
export type FetchResponse = net.FetchResponse

return setmetatable({
	udpSocket = udpSocket,
	udpSocketClose = udpSocketClose,
}, {
	__index = net,
})
