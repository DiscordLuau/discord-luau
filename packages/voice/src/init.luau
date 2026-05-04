local connection = require("@self/connection")
local webSocket = require("@self/websocket")
local udp = require("@self/udp")
local rtp = require("@self/rtp")
local dave = require("@self/dave")
local jitter = require("@self/jitter")

export type Connection = connection.Connection
export type WebSocketTransport = webSocket.WebSocketTransport
export type UdpTransport = udp.UdpTransport
export type RtpCrypto = rtp.RtpCrypto
export type DaveManager = dave.DaveManager
export type Jitter = jitter.Jitter

--[=[
	@class Voice

	Interface for the discord-luau Voice package.
]=]

--[=[
	@prop connection Voice.Connection
	@within Voice
]=]

--[=[
	@prop webSocket Voice.WebSocketTransport
	@within Voice
]=]

--[=[
	@prop udp Voice.UdpTransport
	@within Voice
]=]

--[=[
	@prop rtp Voice.RtpCrypto
	@within Voice
]=]

--[=[
	@prop dave Voice.DaveManager
	@within Voice
]=]

--[=[
	@prop jitter Voice.Jitter
	@within Voice
]=]

return {
	connection = connection,
	webSocket = webSocket,
	udp = udp,
	rtp = rtp,
	dave = dave,
	jitter = jitter,
}
