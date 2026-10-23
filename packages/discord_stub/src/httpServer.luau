--[=[
	@class DiscordStub.HttpServer
	@__index Prototype

	A localhost HTTP server with the `/gateway/bot` default. `new` starts it on an ephemeral port and stores the
	handler; the handler may answer any route by returning a response or a raw string body, and falls through to the
	default by returning `nil`.
]=]

--[=[
	@prop handler Handler?
	@within DiscordStub.HttpServer
	The test's handler, which answers every request before the default routes.
]=]

--[=[
	@prop gatewayUrl function
	@within DiscordStub.HttpServer
	Returns the websocket URL, or nil when no websocket server exists.
]=]

--[=[
	@prop onStop function?
	@within DiscordStub.HttpServer
	Called with the handle after it stops.
]=]

--[=[
	@prop server any?
	@within DiscordStub.HttpServer
	The Zune server handle, nil after it stops.
]=]

--[=[
	@prop port number
	@within DiscordStub.HttpServer
	The ephemeral port the server bound to.
]=]

--[=[
	@prop url string
	@within DiscordStub.HttpServer
	The server's base URL, `http://127.0.0.1:{port}`.
]=]

local apiTypes = require("../luau_packages/api_types")

local loopback = require("./loopback")

local HttpServer = {}

HttpServer.Interface = {}
HttpServer.Prototype = {}

--[=[
	@within DiscordStub.HttpServer
	@private

	Answers a request the handler left alone: `GET /api/v10/gateway/bot` returns the websocket URL, or a 503 before
	the websocket server exists; anything else is a 404.
]=]
function HttpServer.Prototype.defaultResponse(self: HttpServer, request: ZuneRequest): ZuneResponse
	if request.method == "GET" and request.path == "/api/v10/gateway/bot" then
		local gatewayUrl = self.gatewayUrl()

		if not gatewayUrl then
			return loopback.jsonResponse(503, {
				message = "discord_stub: create the websocket server before asking for the gateway",
				code = 0,
			})
		end

		local body: apiTypes.GetGatewayBotResponse = {
			url = gatewayUrl,
			shards = 1,
			session_start_limit = {
				total = 1000,
				remaining = 999,
				reset_after = 60000,
				max_concurrency = 1,
			},
		}

		return loopback.jsonResponse(200, body)
	end

	return loopback.notFoundResponse()
end

--[=[
	@within DiscordStub.HttpServer

	Answers one request: the handler first, then the default.
]=]
function HttpServer.Prototype.respond(self: HttpServer, request: ZuneRequest): string | ZuneResponse
	local response = self.handler and self.handler(request)

	if response then
		return response
	end

	return self:defaultResponse(request)
end

--[=[
	@within DiscordStub.HttpServer

	Stops listening. Safe to call twice.
]=]
function HttpServer.Prototype.stop(self: HttpServer)
	if self.server then
		self.server:stop()
		self.server = nil
	end

	if self.onStop then
		self.onStop(self)
	end
end

--[=[
	@within DiscordStub.HttpServer

	Creates and starts the server on `127.0.0.1` with an ephemeral port.
]=]
function HttpServer.Interface.new(settings: {
	handler: Handler?,
	gatewayUrl: () -> string?,
	onStop: ((server: HttpServer) -> ())?,
}): HttpServer
	local self = setmetatable(
		{
			handler = settings.handler,
			gatewayUrl = settings.gatewayUrl,
			onStop = settings.onStop,
			server = nil,
			port = 0,
			url = "",
		} :: HttpServer,
		{ __index = HttpServer.Prototype }
	)
	local server = loopback.serve({
		request = function(request)
			return self:respond(request)
		end,
	})

	self.server = server
	self.port = server:getPort()
	self.url = `http://127.0.0.1:{self.port}`

	return self
end

type ZuneServer = any
type ZuneRequest = HttpServerRequest
type ZuneResponse = HttpServerResponse

export type Handler = (request: ZuneRequest) -> (string | ZuneResponse)?

export type HttpServer = typeof(HttpServer.Prototype) & {
	handler: Handler?,
	gatewayUrl: () -> string?,
	onStop: ((server: HttpServer) -> ())?,
	server: ZuneServer?,
	port: number,
	url: string,
}

return HttpServer.Interface
