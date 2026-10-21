--[=[
	@class DiscordStub
	@__index Prototype

	One local Discord world: a clock, an HTTP server and a gateway websocket server. `clock = "virtual"` runs the
	world 100x faster than real time. `discordStub.recordEmits(emitter)` records every call an emitter fires.
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

local clock = require("@self/clock")
local httpServer = require("@self/httpServer")
local testing = require("@self/testing")
local webSocketServer = require("@self/webSocketServer")

local DiscordStub = {}

DiscordStub.Interface = {
	recordEmits = testing.recordEmits,
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

	Runs one test scenario, then `teardown` (the caller's own cleanup, such as closing a shard), then stops the world,
	even when either of them throws. Returns the scenario's error, else the teardown's error, else the first error a
	websocket handler raised, else nil.
]=]
function DiscordStub.Prototype.runScenario(self: DiscordStub, scenario: () -> ...any, teardown: (() -> ())?): string?
	local ran, scenarioError = pcall(scenario)
	local handlerErrors = if self.webSocketServer then self.webSocketServer.handlerErrors else {}
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

	return handlerErrors[1]
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

export type DiscordStub = typeof(DiscordStub.Prototype) & {
	clock: clock.Clock,
	httpServer: httpServer.HttpServer?,
	webSocketServer: webSocketServer.WebsocketServer?,
	restUrl: string?,
}

return DiscordStub.Interface
