local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")

--[=[
	@class Rest.Request
	@__index Prototype

	Request is a class that represents a single HTTP request. The idea behind this class is to provide
	some sort of structure and boilerplate for making HTTP requests.

	by default, this class will add the following headers:
	- User-Agent: "DiscordLuau"
	- Authorization: "Bot <token>"
	- Content-Type: "application/json"
]=]
local Request = {}

Request.Prototype = {}
Request.Interface = {}

--[=[
	@within Rest.Request

	Responsible for setting the Body of this request. Body must be a string.
]=]
function Request.Prototype.setBody(self: Request, body: string)
	self.body = body
end

--[=[
	@within Rest.Request

	Allows us to define flags for this request, used to flag requests that could potentially contain attachments. and,
		therefore need to be translated into formdata before we push anything.
]=]
function Request.Prototype.setFlag(self: Request, name: string, value: boolean)
	self.flags[name] = value
end

--[=[
	@within Rest.Request

	Responsible for adding to the Url Params of this request. Both the param key and values are strings.
]=]
function Request.Prototype.addUrlParam(self: Request, paramName: string, paramValue: string)
	self.urlParams[paramName] = paramValue
end

--[=[
	@within Rest.Request

	Responsible for adding to the Headers of this request. Both the header key and values are strings.

	You are not allowed to set the following headers:
	- User-Agent
	- Authorization
]=]
function Request.Prototype.addHeader(self: Request, headerName: string, headerValue: string)
	assert(headerName ~= "user-agent", `User-Agent header cannot be set!`)
	assert(headerName ~= "authorization", `Authorization header cannot be set!`)

	self.headers[headerName] = headerValue
end

--[=[
	@within Rest.Request

	Responsible for setting the URL of this request. URL must be a string, and formatted like so:
	
	- https://example.com/path/to/resource
]=]
function Request.Prototype.setUrl(self: Request, url: string)
	-- FIXME: why is this commented out?
	-- assert(url:match("^%a+://"), `Request URL '{url}' is not a valid URL`)

	self.url = url
end

--[=[
	@within Rest.Request

	Responsible for setting the Method of this request. Method must be one of GET, POST, PUT, PATCH, or DELETE.

	Methods define the nature of the request, and the response.
]=]
function Request.Prototype.setMethod(self: Request, method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE")
	assert(
		method == "GET" or method == "POST" or method == "PUT" or method == "PATCH" or method == "DELETE",
		`Request method must be one of GET, POST, PUT, PATCH, or DELETE.`
	)

	self.method = method
end

--[=[
	@within Rest.Request

	Responsible for validating the Authorization token of this request. Some calls require token authorization, and
	some do not, so the relevant calls should assert that the token is set.
]=]
function Request.Prototype.assertToken(self: Request)
	assert(self.token, `Request authorization token is not set!`)
end

--[=[
	@within Rest.Request

	Enables developers to add a hook to this request. Hooks are functions that are called before or after the request is
	executed. Hooks are useful for things like logging, or modifying the request before it is executed.

	The hook callback should return a boolean, and if it returns false, the request will not be executed.
]=]
function Request.Prototype.addHook(
	self: Request,
	hookState: "BeforeRequest" | "AfterRequest",
	hookCallback: (RequestInformation, stdPolyfills.FetchResponse?) -> any
)
	if hookState == "AfterRequest" then
		table.insert(self.afterHooks, hookCallback)
	elseif hookState == "BeforeRequest" then
		table.insert(self.beforeHooks, hookCallback)
	else
		error(`Invalid hook state '{hookState}'`)
	end
end

--[=[
	@within Rest.Request

	Responsible for executing this request asynchronously. This will return a async that will resolve when the request is
	completed.

	This function will decode the response body, and return a table with the following keys:
		- headers: A table of headers returned from the request.
		- body: The body of the request, decoded from the response.
]=]
function Request.Prototype.executeAsync<Resolve>(self: Request)
	return future.Future.new(function()
		assert(self.method, `Request method is not set!`)
		assert(self.url, `Request URL is not set!`)
		assert(self.headers, `Request headers are not set!`)

		local headerTable: stdPolyfills.HttpHeaderMap = {}
		local baseUrl = `https://discord.com/api/v{self.restApiVersion}{self.url}`
		local hasUrlParams = next(self.urlParams) ~= nil

		headerTable["user-agent"] = "DiscordBot (https://github.com/DiscordLuau/discord-luau, 0.1.0)"
		headerTable["content-type"] = "application/json"

		if self.token then
			headerTable["authorization"] = `Bot {self.token}`
		end

		for header, value in self.headers do
			headerTable[header] = value
		end

		if hasUrlParams then
			baseUrl = baseUrl .. "?"
		end

		for param, value in self.urlParams do
			baseUrl = baseUrl .. `{param}={value}&`
		end

		if hasUrlParams then
			baseUrl = baseUrl:sub(1, #baseUrl - 1)
		end

		for _, hook in self.beforeHooks do
			local success, response = hook({
				requestUrl = self.url,
				url = baseUrl,
				method = self.method,
				body = self.body,
				headers = headerTable,
			})

			if success then
				if response then
					local info = response :: RequestInformation

					baseUrl = info.url
					self.method = info.method :: any
					self.body = info.body
					headerTable = info.headers
				end
			else
				error(
					`Hook: {debug.info(hook, "s")} returned false: '{response or `No reason provided`}', failed to send Network request!`
				)
			end
		end

		local request = stdPolyfills.net.request({
			url = baseUrl,
			method = self.method,
			body = self.body,
			headers = headerTable,
		} :: stdPolyfills.FetchParams)

		for _, hook in self.afterHooks do
			local success, response = hook({
				requestUrl = self.url,
				url = baseUrl,
				method = self.method,
				body = self.body,
				headers = headerTable,
			}, request)

			if not success then
				error(
					`Hook: {debug.info(hook, "s")} returned false: '{response or `No reason provided`}', failed to handle Network request!`
				)
			end
		end

		if not request.ok then
			error(setmetatable({
				statusCode = request.statusCode,
				statusMessage = request.statusMessage,
				body = request.body,
			}, {
				__tostring = function(self)
					return `HTTP REST Request failed: {self.statusCode} {self.statusMessage}\n{self.body}`
				end,
			}))
		end

		local decodeSuccess, decodedBody = pcall(stdPolyfills.serde.decode, "json" :: "json", request.body)

		return {
			headers = request.headers,
			body = (decodeSuccess and decodedBody or request.body) :: Resolve,
		}
	end) :: future.FutureLike<string, {
		headers: stdPolyfills.HttpHeaderMap,
		body: Resolve,
	}>
end

--[=[
	@within Rest.Request

	Constructor for the Request object.
]=]
function Request.Interface.new(settings: {
	token: string?,

	restApiVersion: number,
}): Request
	return setmetatable(
		{
			token = settings.token,
			restApiVersion = settings.restApiVersion,
			flags = {},
			headers = {},
			urlParams = {},
			beforeHooks = {},
			afterHooks = {},
		} :: Request,
		{ __index = Request.Prototype }
	)
end

export type RequestInformation = {
	url: string,
	method: string,
	body: string,
	headers: stdPolyfills.HttpHeaderMap,
	requestUrl: string,
}

export type Request = typeof(Request.Prototype) & {
	token: string?,
	restApiVersion: number,

	beforeHooks: { (RequestInformation) -> (boolean?, string | RequestInformation?) },
	afterHooks: { (RequestInformation, stdPolyfills.FetchResponse) -> (boolean?, string | RequestInformation?) },

	method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE",
	url: string,
	flags: { [string]: boolean },
	headers: { [string]: string },
	urlParams: { [string]: string },
	body: string,
}

return Request.Interface
