local http = require("@eryx/http")
local websocket = require("@eryx/websocket")

local net = {}

local function urlEncodeChar(character: string): string
	return string.format("%%%02X", string.byte(character))
end

function net.urlEncode(url: string, binary: boolean?): string
	return (string.gsub(url, "[^%w%-%.%_%~]", urlEncodeChar))
end

function net.request(config: string | {
	url: string,
	method: string?,
	body: (string | buffer)?,
	query: { [string]: any }?,
	headers: { [string]: string }?,
})
	local url: string
	local method = "GET"
	local headers: { [string]: string }? = nil
	local body: string? = nil
	local query: { [string]: any }? = nil

	if type(config) == "string" then
		url = config
	else
		url = config.url
		method = config.method or "GET"
		headers = config.headers
		query = config.query

		if config.body then
			body = if type(config.body) == "buffer"
				then buffer.tostring(config.body :: buffer)
				else config.body :: string
		end
	end

	local response = http.request(method, url, {
		headers = headers,
		body = body,
		query = query,
	})

	return {
		ok = response.status >= 200 and response.status < 300,
		statusCode = response.status,
		statusMessage = response.reason,
		headers = response.headers,
		body = response.body,
	}
end

-- ws:receive() yields until a message arrives or the connection closes, mapping directly to the next() interface
function net.socket(url: string)
	local ws = websocket.connect(url)
	local value = { closeCode = nil :: number? }

	function value.next(): string?
		local message = ws:receive()

		if not message then
			return nil
		end

		return if type(message.data) == "buffer"
			then buffer.tostring(message.data :: buffer)
			else message.data :: string
	end

	function value.send(message: (string | buffer)?, _asBinaryMessage: boolean?)
		if message then
			local data = if type(message) == "buffer" then buffer.tostring(message) else message :: string
			ws:send(data)
		end
	end

	function value.close(code: number?)
		value.closeCode = code
		ws:close(code)
	end

	return value
end

return net
