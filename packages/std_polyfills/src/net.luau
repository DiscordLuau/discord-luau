--[=[
	@class StdPolyfills.net
]=]

local runtime = require("./runtime")

local net = {}

--[=[
	@within StdPolyfills.net

	Encodes the given string using URL encoding.
]=]
function net.urlEncode(url: string, binary: boolean?): string
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/net").urlEncode(url, binary)
	elseif target == "Zune" then
		return require("./zune/net").urlEncode(url, binary)
	elseif target == "Roblox" then
		return require("./roblox/net").urlEncode(url, binary)
	elseif target == "Eryx" then
		return require("./eryx/net").urlEncode(url, binary)
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
		return require("./lune/net").request(config)
	elseif target == "Zune" then
		return require("./zune/net").request(config :: any)
	elseif target == "Roblox" then
		return require("./roblox/net").request(config :: any)
	elseif target == "Eryx" then
		return require("./eryx/net").request(config :: any)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.net

	Connects to a TCP web socket at the given URL.

	Throws an error if the server at the given URL does not support web sockets, or if a miscellaneous network or I/O
		error occurs.
]=]
function net.tcpSocket(url: string): WebSocket
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/net").socket(url) :: any
	elseif target == "Zune" then
		return require("./zune/net").socket(url) :: any
	elseif target == "Roblox" then
		return require("./roblox/net").socket(url) :: any
	elseif target == "Eryx" then
		return require("./eryx/net").socket(url) :: any
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.net

	Connects to a UDP web socket at the given URL.

	Throws an error if the server at the given URL does not support web sockets, or if a miscellaneous network or I/O
		error occurs.
]=]
function net.udpSocket(host: string, port: number): UdpSocket
	local target = runtime.assertRuntime()

	if target == "Lune" then
		error(`UDP sockets are not available in Lune`)
	elseif target == "Zune" then
		return require("./zune/net").udpSocket(host, port)
	elseif target == "Roblox" then
		error(`UDP sockets are not available in Roblox`)
	elseif target == "Eryx" then
		error(`UDP sockets are not available via this polyfill on Eryx`)
	end

	error(`Out of reach`)
end

type HttpQueryOrHeaderMap = { [string]: string | { string } }
export type HttpQueryMap = HttpQueryOrHeaderMap
export type HttpHeaderMap = HttpQueryOrHeaderMap

export type FetchParamsOptions = {
	decompress: boolean?,
}

export type UdpSocket = {
	closeCode: number?,
	close: (code: number?) -> (),
	send: (message: (string | buffer)?, asBinaryMessage: boolean?) -> (),
	next: () -> string?,
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
