local net = require("@std-polyfills/net")

local future = require("@vendor/future")

--[[
	Request is a class that represents a single HTTP request. The idea behind this class is to provide
	some sort of structure and boilerplate for making HTTP requests.

	by default, this class will add the following headers:
	- User-Agent: "DiscordLuau"
	- Authorization: "Bot <token>"
	- Content-Type: "application/json"
]]
local Request = {}

Request.Prototype = {}
Request.Interface = {}

--[[
	Responsible for setting the Body of this request. Body must be a string.
]]
function Request.Prototype.setBody(self: Request, body: string)
	self.body = body
end

--[[
	Responsible for setting the Headers of this request. Headers must be a table, where the key and values are strings.

	You are not allowed to set the following headers:
	- User-Agent
	- Authorization
]]
function Request.Prototype.setHeaders(self: Request, headers: { [string]: string })
	assert(headers["user-agent"], `User-Agent header cannot be set!`)
	assert(headers["authorization"], `Authorization header cannot be set!`)

	self.headers = headers
end

--[[
	Responsible for setting the URL of this request. URL must be a string, and formatted like so:
	
	- https://example.com/path/to/resource
]]
function Request.Prototype.setUrl(self: Request, url: string)
	assert(url:match("^%a+://"), `Request URL '{url}' is not a valid URL`)

	self.url = url
end

--[[
	Responsible for setting the Method of this request. Method must be one of GET, POST, PUT, PATCH, or DELETE.

	Methods define the nature of the request, and the response.
]]
function Request.Prototype.setMethod(self: Request, method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE")
	assert(
		method == "GET" or method == "POST" or method == "PUT" or method == "PATCH" or method == "DELETE",
		`Request method must be one of GET, POST, PUT, PATCH, or DELETE.`
	)

	self.method = method
end

--[[
	Responsible for validating the Authorization token of this request. Some calls require token authorization, and
	some do not, so the relevant calls should assert that the token is set.
]]
function Request.Prototype.assertToken(self: Request)
	assert(self.token, `Request authorization token is not set!`)
end

--[[
	Responsible for executing this request asynchronously. This will return a future that will resolve when the request is
	completed.

	This function will decode the response body, and return a table with the following keys:
		- headers: A table of headers returned from the request.
		- body: The body of the request, decoded from the response.
]]
function Request.Prototype.executeAsync<Resolve>(self: Request): future.Future<{ headers: { [string]: string }, body: Resolve }>
	return future.new(function()
		assert(self.method, `Request method is not set!`)
		assert(self.url, `Request URL is not set!`)
		assert(self.headers, `Request headers are not set!`)

		if self.method == "POST" then
			assert(self.body, `Request body is not set!`)
		end

		local headerTable = {}

		headerTable["user-agent"] = "DiscordBot (https://github.com/DiscordLuau/discord-luau, 0.1.0)"
		headerTable["content-type"] = "application/json"

		if self.token then
			headerTable["authorization"] = `Bot {self.token}`
		end

		for header, value in self.headers do
			headerTable[header] = value
		end

		local request = net.request({
			url = `https://discord.com/api/{self.restApiVersion}{self.url}`,
			method = self.method,
			body = self.body,
			headers = headerTable,
		})

		if not request.ok then
			error(`HTTP REST Request failed: {request.statusCode} {request.statusMessage}`)
		end

		return {
			headers = request.headers,
			body = net.jsonDecode(request.body),
		}
	end)
end

--[[
	Constructor for the Request object.
]]
function Request.Interface.new(settings: {
	token: string?,

	restApiVersion: number,
}): Request
	return setmetatable(
		{
			token = settings.token,
			restApiVersion = settings.restApiVersion,
			headers = {},
		} :: Request,
		{ __index = Request.Prototype }
	)
end

export type Request = typeof(Request.Prototype) & {
	token: string?,
	restApiVersion: number,

	method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE",
	url: string,
	headers: { [string]: string },
	body: string,
}

return Request.Interface
