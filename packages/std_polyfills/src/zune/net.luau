-- selene: allow(undefined_variable)
local zuneNet = zune.net
local zuneTask = zune.task

local net = {}

local function urlEncodeCharacter(character: string): string
	return string.format("%%%02X", string.byte(character))
end

local function buildQueryString(query: { [string]: string | { string } }): string
	local parts = {}

	for key, value in query do
		if type(value) == "table" then
			for _, item in value do
				table.insert(parts, net.urlEncode(key) .. "=" .. net.urlEncode(item))
			end
		else
			table.insert(parts, net.urlEncode(key) .. "=" .. net.urlEncode(value :: string))
		end
	end

	return table.concat(parts, "&")
end

function net.urlEncode(url: string, _binary: boolean?): string
	return (string.gsub(url, "[^%w%-%.%_%~]", urlEncodeCharacter))
end

function net.request(config: string | {
	url: string,
	method: string?,
	body: (string | buffer)?,
	query: { [string]: any }?,
	headers: { [string]: string }?,
})
	local url: string
	local options: { method: string?, headers: { [string]: string }?, body: (string | buffer)?, max_body_size: number? } =
		{}

	if type(config) == "string" then
		url = config
	else
		url = config.url
		options.method = config.method
		options.headers = config.headers
		options.body = config.body

		if config.query then
			local queryString = buildQueryString(config.query)

			if #queryString > 0 then
				url = url .. (if string.find(url, "?", 1, true) then "&" else "?") .. queryString
			end
		end
	end

	options.max_body_size = 1024 * 1024 * 256

	local response = zuneNet.http.request(url, options :: any)

	return {
		ok = response.ok,
		statusCode = response.status_code,
		statusMessage = response.status_reason,
		headers = response.headers,
		body = response.body,
	}
end

function net.socket(url: string)
	local messageQueue: { QueuedMessage } = {}
	local waitingThread: thread? = nil
	local isOpen = true
	local value = { closeCode = nil :: number? }

	local function wakeWaitingThread()
		local thread = waitingThread

		waitingThread = nil

		-- A waiting thread can be closed by its owner (a voice transport tearing down) before the socket wakes it.
		if thread and coroutine.status(thread) == "suspended" then
			zuneTask.defer(thread)
		end
	end

	local webSocket = zuneNet.http.websocket(url, {
		message = function(_webSocket, message: string | buffer)
			if type(message) == "buffer" then
				table.insert(messageQueue, { text = buffer.tostring(message), isBinary = true })
			else
				table.insert(messageQueue, { text = message, isBinary = false })
			end

			wakeWaitingThread()
		end,
		close = function(_webSocket, code: number?)
			isOpen = false
			value.closeCode = code
			wakeWaitingThread()
		end,
	})

	function value.nextMessage(): (string?, boolean?)
		if #messageQueue == 0 and isOpen then
			waitingThread = coroutine.running()
			coroutine.yield()
		end

		local queued = table.remove(messageQueue, 1)

		if not queued then
			return
		end

		return queued.text, queued.isBinary
	end

	function value.next(): string?
		local text = value.nextMessage()

		return text
	end

	function value.close(code: number?)
		webSocket:close(code)
	end

	function value.send(message: (string | buffer)?, _asBinaryMessage: boolean?)
		if message then
			webSocket:send(message)
		end
	end

	return value
end

function net.udpSocket(host: string, port: number)
	local handle = zuneNet.createSocket(zuneNet.ADDRF.INET, zuneNet.SOCKF.DGRAM, zuneNet.IPPROTO.UDP)
	local value = { closeCode = nil :: number? }

	handle:connect(host, port)

	function value.send(message: (string | buffer)?, _asBinaryMessage: boolean?)
		if message then
			handle:send(message)
		end
	end

	function value.next(): string?
		local response = handle:recv(65536)

		if not response then
			return
		end

		return buffer.tostring(response)
	end

	function value.close(_code: number?)
		handle:close()
	end

	return value
end

type QueuedMessage = { text: string, isBinary: boolean }

return net
