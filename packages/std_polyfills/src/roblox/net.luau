--# selene: allow(undefined_variable)
local HttpService = game:GetService("HttpService")

local net = {}

--[=[
	@within StdPolyfills.net
	@private

	Resumes `co` on the next scheduler step if it is still waiting; a socket event can arrive after the waiter has moved on.
]=]
local function wakeIfSuspended(co: thread)
	if coroutine.status(co) == "suspended" then
		task.defer(co)
	end
end

local function urlEncodeChar(character: string): string
	return string.format("%%%02X", string.byte(character))
end

local function buildQueryString(query: { [string]: string | { string } }): string
	local parts = {}

	for key, value in query do
		if type(value) == "table" then
			for _, entry in value do
				table.insert(parts, net.urlEncode(key) .. "=" .. net.urlEncode(entry))
			end
		else
			table.insert(parts, net.urlEncode(key) .. "=" .. net.urlEncode(value :: string))
		end
	end

	return table.concat(parts, "&")
end

-- HttpService:UrlEncode only encodes individual values, not full URLs; manual encoding handles raw strings
function net.urlEncode(url: string, _binary: boolean?): string
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
	local headers: { [string]: string } = {}
	local body = ""

	if type(config) == "string" then
		url = config
	else
		url = config.url
		method = config.method or "GET"
		headers = config.headers or {}

		if type(config.body) == "buffer" then
			body = buffer.tostring(config.body :: buffer)
		else
			body = (config.body or "") :: string
		end

		if config.query then
			local queryString = buildQueryString(config.query)

			if #queryString > 0 then
				url = url .. (if string.find(url, "?", 1, true) then "&" else "?") .. queryString
			end
		end
	end

	-- Roblox rejects a Body field entirely on GET/HEAD requests
	local requestParams: { [string]: any } = {
		Url = url,
		Method = method,
		Headers = headers,
	}

	if method ~= "GET" and method ~= "HEAD" then
		requestParams.Body = body
	end

	local response = HttpService:RequestAsync(requestParams)

	return {
		ok = response.Success,
		statusCode = response.StatusCode,
		statusMessage = response.StatusMessage,
		headers = response.Headers,
		body = response.Body,
	}
end

-- Adapts Roblox's CreateWebStreamClient to the pull-based next() interface expected by the shard receive loop;
-- yields until the connection is established (Opened fires) before returning
function net.socket(url: string)
	local messageQueue: { string } = {}
	local receiveWaiter: thread? = nil
	local isOpen = false
	local value = { closeCode = nil :: number? }
	local ws = HttpService:CreateWebStreamClient(Enum.WebStreamClientType.WebSocket, {
		Url = url,
	})
	local connectWaiter: thread? = coroutine.running()
	local connectError: string? = nil
	local socketError: string? = nil

	ws.Opened:Connect(function(_statusCode: number, _headers: { [string]: string })
		isOpen = true

		if connectWaiter then
			local co = connectWaiter
			connectWaiter = nil

			wakeIfSuspended(co)
		end
	end)

	ws.MessageReceived:Connect(function(message: string)
		table.insert(messageQueue, message)

		if receiveWaiter then
			local co = receiveWaiter
			receiveWaiter = nil

			wakeIfSuspended(co)
		end
	end)

	ws.Closed:Connect(function()
		if connectWaiter then
			local co = connectWaiter

			connectError = `WebSocket closed before opening: {url}`
			connectWaiter = nil
			wakeIfSuspended(co)
		end

		isOpen = false

		if receiveWaiter then
			local co = receiveWaiter
			receiveWaiter = nil

			wakeIfSuspended(co)
		end
	end)

	ws.Error:Connect(function(statusCode: number, errorMessage: string)
		local description = `WebSocket error {statusCode}: {errorMessage}`

		if connectWaiter then
			local co = connectWaiter

			connectError = description
			connectWaiter = nil
			wakeIfSuspended(co)
		end

		socketError = description
		isOpen = false

		if receiveWaiter then
			local co = receiveWaiter
			receiveWaiter = nil

			wakeIfSuspended(co)
		end
	end)

	-- Block until Opened (or Error/Closed) fires
	coroutine.yield()

	if connectError then
		error(connectError)
	end

	local function raiseSocketError()
		if socketError then
			local description = socketError

			socketError = nil
			error(description)
		end
	end

	function value.next(): string?
		if #messageQueue > 0 then
			return table.remove(messageQueue, 1)
		end

		if not isOpen then
			raiseSocketError()

			return
		end

		receiveWaiter = coroutine.running()
		coroutine.yield()

		local message = table.remove(messageQueue, 1)

		if not message then
			raiseSocketError()
		end

		return message
	end

	function value.nextMessage(): (string?, boolean?)
		return value.next()
	end

	function value.send(message: (string | buffer)?, _asBinaryMessage: boolean?)
		if message then
			local data = if type(message) == "buffer" then buffer.tostring(message) else message :: string
			ws:Send(data)
		end
	end

	function value.close(_code: number?)
		isOpen = false
		ws:Close()
	end

	return value
end

return net
