local luteNet = require("@std/net")
local luteTask = require("@std/task")

local function urlEncode(str: string, _binary: boolean?): string
	return (
		string.gsub(str, "[^A-Za-z0-9%-%.%_%~]", function(character)
			return string.format("%%%02X", string.byte(character))
		end)
	)
end

local function normalizeResponse(response: any): any
	return {
		ok = (response.status or response.statusCode or 0) >= 200
			and (response.status or response.statusCode or 0) < 300,
		statusCode = response.status or response.statusCode or 0,
		statusMessage = response.statusText or response.statusMessage or "",
		headers = response.headers or {},
		body = response.body or "",
	}
end

-- Lute's native net.request does not understand a `query` field in opts;
-- build the query string into the URL ourselves so parameters are not dropped.
local function buildQueryString(query: { [string]: string | { string } }): string
	local parts = {}

	for key, value in query do
		if type(value) == "table" then
			for _, item in value do
				table.insert(parts, urlEncode(key) .. "=" .. urlEncode(item))
			end
		else
			table.insert(parts, urlEncode(key) .. "=" .. urlEncode(value :: string))
		end
	end

	return table.concat(parts, "&")
end

local net = {}

function net.urlEncode(url: string, binary: boolean?): string
	return urlEncode(url, binary)
end

function net.request(config: any): any
	local url = if typeof(config) == "string" then config else config.url

	local metadata: any = if typeof(config) == "table"
		then {
			method = config.method,
			body = config.body,
			headers = config.headers,
		}
		else nil

	if typeof(config) == "table" and config.query then
		local queryString = buildQueryString(config.query)

		if #queryString > 0 then
			url = url .. (if string.find(url, "?", 1, true) then "&" else "?") .. queryString
		end
	end

	return normalizeResponse(luteNet.request(url, metadata))
end

function net.socket(url: string): any
	local ok, netClient = pcall(require, "@lute/net/client")

	if not ok then
		error(`WebSocket unavailable on Lute: @lute/net/client could not be loaded: {netClient}`)
	end

	local queue: { string } = {}
	local closed = false
	local socketError: string? = nil

	local wrapper: any = {
		closeCode = nil,
	}

	local socket = netClient.websocket(url, {
		onmessage = function(message: string | buffer)
			table.insert(queue, if typeof(message) == "buffer" then buffer.tostring(message) else message)
		end,
		onclose = function(code: number, _reason: string)
			wrapper.closeCode = code
			closed = true
		end,
		onerror = function(errorMessage: string)
			socketError = tostring(errorMessage)
			closed = true
		end,
	})

	wrapper.close = function(code: number?)
		wrapper.closeCode = code
		closed = true

		pcall(function()
			socket:close(code)
		end)
	end

	wrapper.send = function(message: string | buffer, _asBinaryMessage: boolean?)
		socket:send(if typeof(message) == "buffer" then buffer.tostring(message) else message)
	end

	wrapper.next = function(): string?
		while #queue == 0 and not closed do
			luteTask.wait(0.01)
		end

		if #queue > 0 then
			return table.remove(queue, 1)
		end

		if socketError then
			local errorMessage = socketError

			socketError = nil
			error(`WebSocket error: {errorMessage}`)
		end

		return nil
	end

	wrapper.nextMessage = function(): (string?, boolean?)
		return wrapper.next()
	end

	return wrapper
end

return net
