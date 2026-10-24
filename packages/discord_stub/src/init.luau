--[=[
	@class DiscordStub
	@__index Prototype

	One local Discord world: a clock, an HTTP server, a gateway websocket server and a voice server with its UDP
	server. `clock = "virtual"` runs the world 100x faster than real time. `discordStub.recordEmits(emitter)` records
	every call an emitter fires, and `discordStub.VoiceServer` and `discordStub.UdpServer` build voice doubles outside
	a world.
]=]

--[=[
	@prop clock Clock
	@within DiscordStub
	The clock the world runs on.
]=]

--[=[
	@prop httpServer HttpServer?
	@within DiscordStub
	The HTTP server, once `createHttpServer` has run.
]=]

--[=[
	@prop webSocketServer WebsocketServer?
	@within DiscordStub
	The gateway websocket server, once `createWebsocketServer` has run.
]=]

--[=[
	@prop restUrl string?
	@within DiscordStub
	The REST base URL of the HTTP server, nil before it exists.
]=]

--[=[
	@prop voiceServer VoiceServer?
	@within DiscordStub
	The voice gateway server, once `createVoiceServer` has run.
]=]

--[=[
	@prop udpServer UdpServer?
	@within DiscordStub
	The voice UDP server `createVoiceServer` started alongside the voice gateway server.
]=]

local clock = require("@self/clock")
local httpServer = require("@self/httpServer")
local testing = require("@self/testing")
local udpServer = require("@self/udpServer")
local voiceServer = require("@self/voiceServer")
local webSocketServer = require("@self/webSocketServer")

local DiscordStub = {}

DiscordStub.Interface = {
	recordEmits = testing.recordEmits,
	VoiceServer = voiceServer,
	UdpServer = udpServer,
}
DiscordStub.Prototype = {}

--[=[
	@within DiscordStub

	Stops every server and puts the real clock back. Safe to call twice.
]=]
function DiscordStub.Prototype.stop(self: DiscordStub)
	if self.webSocketServer then
		self.webSocketServer:stop()
		self.webSocketServer = nil
	end

	if self.voiceServer then
		self.voiceServer:stop()
		self.voiceServer = nil
	end

	if self.udpServer then
		self.udpServer:stop()
		self.udpServer = nil
	end

	if self.httpServer then
		self.httpServer:stop()
		self.httpServer = nil
		self.restUrl = nil
	end

	self.clock:uninstall()
end

--[=[
	@within DiscordStub

	Starts an HTTP server on `127.0.0.1` with an ephemeral port. The handler may return a response or a raw string;
	`nil` falls through to the default routes.
]=]
function DiscordStub.Prototype.createHttpServer(self: DiscordStub, handler: httpServer.Handler?): httpServer.HttpServer
	assert(not self.httpServer, "discord_stub: createHttpServer was already called")

	local server = httpServer.new({
		handler = handler,
		gatewayUrl = function()
			return self.webSocketServer and self.webSocketServer.url
		end,
		onStop = function(server)
			if self.httpServer == server then
				self.httpServer = nil
				self.restUrl = nil
			end
		end,
	})

	self.httpServer = server
	self.restUrl = `{server.url}/api/v10`

	return server
end

--[=[
	@within DiscordStub

	Starts a gateway websocket server on `127.0.0.1` with an ephemeral port. The handler receives the connection and
	the payload, and may return a payload to send instead of the default reply or `false` to send nothing; `nil` falls
	through.
]=]
function DiscordStub.Prototype.createWebsocketServer(
	self: DiscordStub,
	handler: webSocketServer.Handler?
): webSocketServer.WebsocketServer
	assert(not self.webSocketServer, "discord_stub: createWebsocketServer was already called")

	local server = webSocketServer.new({
		clock = self.clock,
		handler = handler,
		voiceServer = self.voiceServer,
		onStop = function(server)
			if self.webSocketServer == server then
				self.webSocketServer = nil
			end
		end,
	})

	self.webSocketServer = server

	return server
end

--[=[
	@within DiscordStub

	Starts a voice UDP server and a voice gateway server on `127.0.0.1`, both on the world clock, and attaches the
	voice server to the gateway websocket server, now or when it is created, so Voice State Update is answered with
	the voice dispatches.
]=]
function DiscordStub.Prototype.createVoiceServer(
	self: DiscordStub,
	options: VoiceServerOptions?
): voiceServer.VoiceServer
	assert(not self.voiceServer, "discord_stub: createVoiceServer was already called")

	local settings: VoiceServerOptions = options or {}
	local udp = udpServer.new({
		onStop = function(server)
			if self.udpServer == server then
				self.udpServer = nil
			end
		end,
	})
	local server = voiceServer.new({
		clock = self.clock,
		udpServer = udp,
		heartbeatIntervalMilliseconds = settings.heartbeatIntervalMilliseconds,
		modes = settings.modes,
		daveProtocolVersion = settings.daveProtocolVersion,
		token = settings.token,
		sessionId = settings.sessionId,
		onStop = function(server)
			if self.voiceServer == server then
				self.voiceServer = nil
			end

			if self.webSocketServer and self.webSocketServer.voiceServer == server then
				self.webSocketServer.voiceServer = nil
			end
		end,
	})

	self.udpServer = udp
	self.voiceServer = server

	if self.webSocketServer then
		self.webSocketServer.voiceServer = server
	end

	return server
end

--[=[
	@within DiscordStub

	Runs one test scenario, then `teardown` (the caller's own cleanup, such as closing a shard), then stops the world,
	even when either of them throws. Returns the scenario's error, else the teardown's error, else the first error a
	websocket handler, the voice server or the UDP server raised, else nil.
]=]
function DiscordStub.Prototype.runScenario(self: DiscordStub, scenario: () -> ...any, teardown: (() -> ())?): string?
	local ran, scenarioError = pcall(scenario)
	local handlerErrors = if self.webSocketServer then self.webSocketServer.handlerErrors else {}
	local voiceErrors = if self.voiceServer then self.voiceServer.errors else {}
	local udpErrors = if self.udpServer then self.udpServer.errors else {}
	local tornDown, teardownError = pcall(function(): ...any
		if teardown then
			teardown()
		end
	end)

	self:stop()

	if not ran then
		return tostring(scenarioError)
	end

	if not tornDown then
		return tostring(teardownError)
	end

	return handlerErrors[1] or voiceErrors[1] or udpErrors[1]
end

--[=[
	@within DiscordStub

	Creates a stub world.
]=]
function DiscordStub.Interface.new(options: { clock: "real" | "virtual"?, polyfills: any? }?): DiscordStub
	local mode: "real" | "virtual" = if options and options.clock then options.clock else "real"
	local polyfills = if options then options.polyfills else nil
	local self = setmetatable(
		{
			clock = clock.new(mode, polyfills),
		} :: DiscordStub,
		{ __index = DiscordStub.Prototype }
	)

	self.clock:install()

	return self
end

type VoiceServerOptions = {
	heartbeatIntervalMilliseconds: number?,
	modes: { string }?,
	daveProtocolVersion: number?,
	token: string?,
	sessionId: string?,
}

export type VoiceServer = voiceServer.VoiceServer
export type UdpServer = udpServer.UdpServer

export type DiscordStub = typeof(DiscordStub.Prototype) & {
	clock: clock.Clock,
	httpServer: httpServer.HttpServer?,
	webSocketServer: webSocketServer.WebsocketServer?,
	restUrl: string?,
	voiceServer: voiceServer.VoiceServer?,
	udpServer: udpServer.UdpServer?,
}

return DiscordStub.Interface
