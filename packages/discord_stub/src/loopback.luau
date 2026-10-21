--[=[
	@class DiscordStub.Loopback

	The shared localhost server plumbing: bind on `127.0.0.1` with an ephemeral port, JSON responses, and the
	default 404.
]=]
local stdPolyfills = require("../luau_packages/std_polyfills")

local Loopback = {}

--[=[
	@within DiscordStub.Loopback

	Starts a Zune HTTP server on `127.0.0.1` with an ephemeral port.
]=]
function Loopback.serve(settings: any): Server
	settings.port = 0
	settings.address = "127.0.0.1"

	return zune.net.http.serve(settings)
end

--[=[
	@within DiscordStub.Loopback

	Builds a JSON response with `statusCode` and `value`.
]=]
function Loopback.jsonResponse(statusCode: number, value: any): Response
	return {
		status_code = statusCode,
		headers = { ["content-type"] = "application/json" },
		body = stdPolyfills.serde.encode("json", value),
	}
end

--[=[
	@within DiscordStub.Loopback

	The JSON 404 every default route falls through to.
]=]
function Loopback.notFoundResponse(): Response
	return Loopback.jsonResponse(404, { message = "404: Not Found", code = 0 })
end

type Server = HttpServer
type Request = HttpServerRequest
type Response = HttpServerResponse

return Loopback
