--[=[
	@class StdPolyfills.net
]=]

local runtime = require("@self/runtime")

local net = {}

--[=[
	@within StdPolyfills.net

	Encodes the given string using URL encoding.
]=]
function net.urlEncode(url: string, binary: boolean?): string
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/net").urlEncode(url, binary)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.net

	Sends an HTTP request using the given url and / or parameters, and returns a dictionary that describes the
		response received.

	Only throws an error if a miscellaneous network or I/O error occurs, never for unsuccessful status codes.
]=]
function net.request(config: string | FetchParams): FetchResponse
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/net").request(config)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.net

	Connects to a TCP web socket at the given URL.

	Throws an error if the server at the given URL does not support web sockets, or if a miscellaneous network or I/O
		error occurs.
]=]
function net.tcpSocket(url: string)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("@self/lune/net").socket(url)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.net

	Connects to a UDP web socket at the given URL.

	Throws an error if the server at the given URL does not support web sockets, or if a miscellaneous network or I/O
		error occurs.
]=]
function net.udpSocket(_url: string)
	error(`No Runtimes currently support UDP sockets!`)
end

type HttpQueryOrHeaderMap = { [string]: string | { string } }
export type HttpQueryMap = HttpQueryOrHeaderMap
export type HttpHeaderMap = HttpQueryOrHeaderMap

export type FetchParamsOptions = {
	decompress: boolean?,
}

export type WebSocket = {
	closeCode: number?,
	close: (code: number?) -> (),
	send: (message: (string | buffer)?, asBinaryMessage: boolean?) -> (),
	next: () -> string?,
}

export type FetchResponse = {
	ok: boolean,
	statusCode: number,
	statusMessage: string,
	headers: HttpHeaderMap,
	body: string,
}

export type FetchParams = {
	url: string,
	method: HttpMethod?,
	body: (string | buffer)?,
	query: HttpQueryMap?,
	headers: HttpHeaderMap?,
	options: FetchParamsOptions?,
}

export type HttpMethod = "GET" | "POST" | "PUT" | "DELETE" | "HEAD" | "OPTIONS" | "PATCH"

return net
