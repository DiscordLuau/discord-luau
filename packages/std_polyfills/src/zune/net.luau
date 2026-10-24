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

		-- The owner can close a waiting thread (a voice transport tearing down) before the socket wakes it, or after the
		-- wake is queued but before it runs. Zune still resumes a closed thread it deferred, so both are checked.
		if thread and coroutine.status(thread) == "suspended" then
			zuneTask.defer(function()
				if coroutine.status(thread) == "suspended" then
					zuneTask.spawn(thread)
				end
			end)
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
	local sendingThread: thread? = nil
	local waitingSends: { thread } = {}

	-- Zune's connect is TCP-only on Windows, so the socket stays unconnected and filters by peer itself. It binds
	-- first because a receive on an unbound UDP socket fails at once on Windows.
	handle:bindIp("0.0.0.0", 0)

	-- On macOS Zune keeps one pending write per socket, so a send that overlaps another replaces it, and the first is
	-- never sent and never returns. Sends therefore take turns, and a waiting thread its owner closed is passed over.
	local function startNextSend()
		local nextThread = table.remove(waitingSends, 1)

		sendingThread = nextThread

		if nextThread then
			zuneTask.defer(function()
				if coroutine.status(nextThread) == "suspended" then
					zuneTask.spawn(nextThread)
				elseif sendingThread == nextThread then
					startNextSend()
				end
			end)
		end
	end

	local function waitForTurn(thread: thread)
		if sendingThread and coroutine.status(sendingThread) ~= "dead" then
			table.insert(waitingSends, thread)
			coroutine.yield()
		end

		sendingThread = thread
	end

	function value.send(message: (string | buffer)?, _asBinaryMessage: boolean?)
		if message then
			local thread = coroutine.running()

			waitForTurn(thread)

			local sent, sendError = pcall(handle.sendMsg, handle, port, host, message)

			if sendingThread == thread then
				startNextSend()
			end

			if not sent then
				error(sendError, 0)
			end
		end
	end

	function value.next(): string?
		while true do
			local address, response = handle:recvMsg(65536)

			if address.address == host and address.port == port then
				return buffer.tostring(response)
			end
		end
	end

	function value.close(_code: number?)
		handle:close()
	end

	return value
end

type QueuedMessage = { text: string, isBinary: boolean }

return net
