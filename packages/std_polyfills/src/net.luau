--[=[
    @class std.net
]=]

local runtime = require("runtime")

local net = {}

function net.urlEncode(url: string, binary: boolean?): string
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/net").urlEncode(url, binary)
	end

	error(`Out of reach`)
end

function net.request(config: string | FetchParams): FetchResponse
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/net").request(config)
	end

	error(`Out of reach`)
end

function net.tcpSocket(url: string)
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("lune/net").socket(url)
	end

	error(`Out of reach`)
end

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
