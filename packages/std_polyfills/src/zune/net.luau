-- selene: allow(undefined_variable)
local zuneNet = zune.net
local zuneTask = zune.task

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

function net.request(config: string | { url: string, method: string?, body: (string | buffer)?, query: { [string]: any }?, headers: { [string]: string }? })
	local url: string
	local opts: { method: string?, headers: { [string]: string }?, body: (string | buffer)? } = {}

	if type(config) == "string" then
		url = config
	else
		url = config.url
		opts.method = config.method
		opts.headers = config.headers
		opts.body = config.body

		if config.query then
			local qs = buildQueryString(config.query)
			if #qs > 0 then
				url = url .. (if string.find(url, "?", 1, true) then "&" else "?") .. qs
			end
		end
	end

	local response = zuneNet.http.request(url, opts)

	return {
		ok = response.ok,
		statusCode = response.status_code,
		statusMessage = response.status_reason,
		headers = response.headers,
		body = response.body,
	}
end

function net.socket(url: string)
	local messageQueue: { string } = {}
	local waitingThread: thread? = nil
	local isOpen = true

	local value = { closeCode = nil :: number? }

	local wsHandle = zuneNet.http.websocket(url, {
		message = function(_ws, message: string | buffer)
			local messageStr: string = if type(message) == "buffer" then buffer.tostring(message) else message
			table.insert(messageQueue, messageStr)
			if waitingThread then
				local co = waitingThread
				waitingThread = nil
				zuneTask.defer(co)
			end
		end,
		close = function(_ws, code: number?)
			isOpen = false
			value.closeCode = code
			if waitingThread then
				local co = waitingThread
				waitingThread = nil
				zuneTask.defer(co)
			end
		end,
	})

	function value.next(): string?
		if #messageQueue > 0 then
			return table.remove(messageQueue, 1)
		end
		if not isOpen then
			return nil
		end
		waitingThread = coroutine.running()
		coroutine.yield()
		return table.remove(messageQueue, 1)
	end

	function value.close(code: number?)
		wsHandle:close(code)
	end

	function value.send(message: (string | buffer)?, _asBinaryMessage: boolean?)
		if message ~= nil then
			wsHandle:send(message)
		end
	end

	return value
end

return net
