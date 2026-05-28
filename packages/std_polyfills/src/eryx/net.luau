local http = require("@eryx/http")
local websocket = require("@eryx/websocket")

local net = {}

local function urlEncodeChar(c: string): string
	return string.format("%%%02X", string.byte(c))
end

function net.urlEncode(url: string, _binary: boolean?): string
	return (string.gsub(url, "[^%w%-%.%_%~]", urlEncodeChar))
end

local function buildQueryString(query: { [string]: string | { string } }): string
	local parts = {}
	for key, value in query do
		if type(value) == "table" then
			for _, v in value do
				table.insert(parts, net.urlEncode(key) .. "=" .. net.urlEncode(v))
			end
		else
			table.insert(parts, net.urlEncode(key) .. "=" .. net.urlEncode(value :: string))
		end
	end
	return table.concat(parts, "&")
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
	local headers: { [string]: string } = {}
	local body: string? = nil

	if type(config) == "string" then
		url = config
	else
		url = config.url
		method = config.method or "GET"
		headers = config.headers or {}

		if config.body ~= nil then
			body = if type(config.body) == "buffer" then buffer.tostring(config.body :: buffer) else config.body :: string
		end

		if config.query then
			local qs = buildQueryString(config.query)
			if #qs > 0 then
				url = url .. (if string.find(url, "?", 1, true) then "&" else "?") .. qs
			end
		end
	end

	local response = http.request(method, url, {
		headers = headers,
		body = body,
	})

	return {
		ok = response.status >= 200 and response.status < 300,
		statusCode = response.status,
		statusMessage = response.reason,
		headers = response.headers,
		body = response.body,
	}
end

-- @eryx/websocket exposes a blocking ws:receive() that yields until a message
-- arrives or the connection closes, which maps directly to the next() interface.
function net.socket(url: string)
	local ws = websocket.connect(url)
	local value = { closeCode = nil :: number? }

	function value.next(): string?
		local message = ws:receive()
		if message == nil then
			return nil
		end
		return if type(message.data) == "buffer"
			then buffer.tostring(message.data :: buffer)
			else message.data :: string
	end

	function value.send(message: (string | buffer)?, _asBinaryMessage: boolean?)
		if message ~= nil then
			local str = if type(message) == "buffer" then buffer.tostring(message) else message :: string
			ws:send(str)
		end
	end

	function value.close(code: number?)
		value.closeCode = code
		ws:close(code)
	end

	return value
end

return net
