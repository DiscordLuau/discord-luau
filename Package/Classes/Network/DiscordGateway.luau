local Serde = require("@Std/Serde")
local Net = require("@Std/Net")
local Task = require("@Std/Task")

local Future = require("@Vendor/Future")
local Console = require("@Vendor/Console")

local Construct = require("@Utils/Construct")

local HTTPRatelimit = require("@Network/HTTPRatelimit")
local HTTPScheduler = require("@Network/HTTPScheduler")
local Resolvable = require("@Network/Resolvable")

local EventIn = require("@Network/Middleware/EventIn")

local ResolvableType = require("@Enums/ResolvableType")

local DISCORD_API_VERSION = 9

local BASE_DISCORD_APP_URL = "https://discord.com"
local BASE_DISCORD_APP_API_PREFIX = "api"

local FILE_FORMATS = {
	jpg = "image/jpg",
	jpeg = "image/jpeg",
	png = "image/png",
	webp = "image/webp",
	gif = "image/gif",

	csv = "text/csv",
	txt = "text/plain",
	css = "text/css",
	js = "text/javascript",
	html = "text/html",

	mp4 = "video/mp4",
}

--[=[
	@class Network.DiscordGateway

	DiscordGateway is an internal class responsible for managing communication with the Discord API. This class handles rate limiting, scheduling HTTP requests, and processing events.

	:::caution
	This class is internal and should not be used directly by developers.
	:::
]=]
local DiscordGateway = {}

DiscordGateway.Interface = {}
DiscordGateway.Prototype = {}

DiscordGateway.Prototype.type = "DiscordGateway"

--[=[
	Parses error messages from the Discord API response.
	
	@private
	@method parseErrors
	@param errorTable table -- The table containing error messages.
	@param source string? -- The source of the error (optional).
	@param depth number? -- The depth of the error message (optional).
	@within Network.DiscordGateway
	@return string -- The parsed error message.
]=]
function DiscordGateway.Prototype.parseErrors(
	self: DiscordGateway,
	errorTable: { [any]: any },
	source: string?,
	depth: number?
)
	local _source = source or ""
	local _depth = depth or 0

	for index, value in errorTable do
		if index == "_errors" then
			for _, errorObject in value do
				_source ..= `{string.rep(" ", _depth)}{errorObject.code}: {errorObject.message}\n`
			end
		else
			_source ..= `{string.rep(" ", _depth)}{index}:\n{self:parseErrors(value, _source, _depth + 1)}\n`
		end
	end

	return _source
end

--[=[
	Parses errors from a Discord API response.
	
	@private
	@method parseDiscordAPIErrors
	@param api string -- The API endpoint that was called.
	@param networkResponse Net.FetchResponse -- The response from the network request.
	@within Network.DiscordGateway
	@return string -- The parsed error message.
]=]
function DiscordGateway.Prototype.parseDiscordAPIErrors(
	self: DiscordGateway,
	api: string,
	networkResponse: Net.FetchResponse
)
	local success, messageDecoded = pcall(function()
		return Serde.decode("json", networkResponse.body)
	end)

	if success then
		local discordErrorString = ""

		if messageDecoded.errors then
			discordErrorString = self:parseErrors(messageDecoded.errors)
		end

		return `Discord API Error - {messageDecoded.code} ({messageDecoded.message}): \n\nAPI: {api}\n\nTRACE:\n{discordErrorString}`
	end

	return `Discord HTTP Error - {networkResponse.statusCode} ({networkResponse.statusMessage}): \n{networkResponse.body}`
end

--[=[
	Sends an asynchronous request to the Discord API.
	
	@private
	@method requestAsync
	@param api string -- The API endpoint.
	@param method string -- The HTTP method (e.g., "GET", "POST").
	@param data table? -- The data to send with the request (optional).
	@within Network.DiscordGateway
	@return Vendor.Future -- A Future that resolves with the response.
]=]
function DiscordGateway.Prototype.requestAsync(
	self: DiscordGateway,
	api: string,
	method: "DELETE" | "GET" | "PATCH" | "POST" | "PUT",
	data: Resolvable.Resolvable?,
	headers: { [string]: string }?
)
	return Future.try(function()
		return self.discordScheduler:addTask(function()
			local ratelimitApi = string.gsub(api, "%d+", "-")

			if self.endpointRateLimits[ratelimitApi] and self.endpointRateLimits[ratelimitApi]:isConsumed() then
				while self.endpointRateLimits[ratelimitApi]:isConsumed() do
					Task.wait()
				end
			end

			local bodyObject
			local headerObject = {
				["authorization"] = `Bot {self.discordClient.discordSettings.discordToken}`,
				["content-type"] = "application/json",
			}

			if headers then
				for key, value in headers do
					headerObject[key] = value
				end
			end

			if data then
				if data.type == ResolvableType.JSON then
					bodyObject = Serde.encode("json", data:resolve())
				elseif data.type == ResolvableType.FORMDATA then
					local jsonContent = Serde.encode("json", data:resolve())

					local multiformUuid = `DiscordLuau.{math.random()}`
					local multiformContentBoundary = `{multiformUuid}`
					local multiformContent = ""

					multiformContent ..= `--{multiformContentBoundary}\r\n`
					multiformContent ..= `Content-Disposition: form-data; name="payload_json"\r\n`
					multiformContent ..= `Content-Type: application/json\r\n`

					multiformContent ..= `\r\n`
					multiformContent ..= `{jsonContent}\r\n`

					for index, fileObject in data.metadata.attachments do
						local fileName = fileObject.fileName
						local fileType = string.match(fileObject.fileName, ".+%.(%S+)")
						local fileFormat = FILE_FORMATS[fileType] or "text/plain"

						multiformContent ..= `--{multiformContentBoundary}\r\n`
						multiformContent ..= `Content-Disposition: form-data; name="files[{index - 1}]"; filename="{fileName}"\r\n`
						multiformContent ..= `Content-Type: {fileFormat}\r\n`

						multiformContent ..= `\r\n`
						multiformContent ..= `{fileObject.fileData}\r\n`
					end

					multiformContent ..= `--{multiformContentBoundary}--\r\n`

					bodyObject = multiformContent

					headerObject["content-type"] = `multipart/form-data; boundary={multiformContentBoundary}`
				end

				for key, value in data.metadata.headers do
					headerObject[key] = value
				end
			end

			local networkResponse = Net.request({
				url = `{BASE_DISCORD_APP_URL}/{BASE_DISCORD_APP_API_PREFIX}/v{DISCORD_API_VERSION}/{api}`,
				method = method,
				headers = headerObject,
				body = bodyObject,
			})

			self.reporter:debug(
				`{method} Async to '{api}': {networkResponse.statusCode} - {networkResponse.statusMessage}`
			)

			local ratelimitLimit = tonumber(networkResponse.headers["x-ratelimit-limit"])
			local ratelimitRemaining = tonumber(networkResponse.headers["x-ratelimit-remaining"])
			local ratelimitResetAfter = tonumber(networkResponse.headers["x-ratelimit-reset-after"])

			if ratelimitLimit and ratelimitRemaining and ratelimitResetAfter then
				if not self.endpointRateLimits[ratelimitApi] then
					self.endpointRateLimits[ratelimitApi] = (
						HTTPRatelimit.new(ratelimitLimit, ratelimitRemaining) :: unknown
					) :: HTTPRatelimit.HTTPRatelimit
				end

				self.endpointRateLimits[ratelimitApi]:setRemaining(ratelimitRemaining)
				self.endpointRateLimits[ratelimitApi]:resetAfter(ratelimitResetAfter + 1)

				self.reporter:debug(
					`{method} Rate Limit '{ratelimitLimit - ratelimitRemaining}/{ratelimitLimit}, resetting in {ratelimitResetAfter}'`
				)
			end

			if not networkResponse.ok then
				error(self:parseDiscordAPIErrors(api, networkResponse))
			end

			if networkResponse.body == "" then
				return
			else
				return self.gatewayEventIn:processJSON(Serde.decode("json", networkResponse.body))
			end
		end)
	end)
end

--[=[
	Sends an asynchronous GET request to the Discord API.
	
	@private
	@method getAsync
	@param api string -- The API endpoint.
	@param headers { [string]: string }
	@within Network.DiscordGateway
	@return Vendor.Future -- A Future that resolves with the response.
]=]
function DiscordGateway.Prototype.getAsync(self: DiscordGateway, api: string, headers: { [string]: string }?)
	return Future.try(function()
		local cache = self:getEndpointCache(api)
		local cacheValue = cache and cache:get()

		if cacheValue then
			return cacheValue
		end

		local response = self:requestAsync(api, "GET", nil, headers):await()

		if cache then
			cache:set(response)
		end

		return response
	end)
end

--[=[
	Sends an asynchronous POST request to the Discord API.
	
	@private
	@method postAsync
	@param api string -- The API endpoint.
	@param data table -- The data to send with the request.
	@param headers { [string]: string }
	@within Network.DiscordGateway
	@return Vendor.Future -- A Future that resolves with the response.
]=]
function DiscordGateway.Prototype.postAsync(
	self: DiscordGateway,
	api: string,
	data: any?,
	headers: { [string]: string }?
)
	return self:requestAsync(api, "POST", data, headers)
end

--[=[
	
	Sends an asynchronous PUT request to the Discord API.
	
	@private
	@method putAsync
	@param api string -- The API endpoint.
	@param data table -- The data to send with the request.
	@param headers { [string]: string }
	@within Network.DiscordGateway
	@return Vendor.Future -- A Future that resolves with the response.
]=]
function DiscordGateway.Prototype.putAsync(
	self: DiscordGateway,
	api: string,
	data: any?,
	headers: { [string]: string }?
)
	return self:requestAsync(api, "PUT", data, headers)
end

--[=[
	Sends an asynchronous DELETE request to the Discord API.
	
	@private
	@method deleteAsync
	@param api string -- The API endpoint.
	@param data table? -- The data to send with the request (optional).
	@param headers { [string]: string }
	@within Network.DiscordGateway
	@return Vendor.Future -- A Future that resolves with the response.
]=]
function DiscordGateway.Prototype.deleteAsync(
	self: DiscordGateway,
	api: string,
	data: any?,
	headers: { [string]: string }?
)
	return self:requestAsync(api, "DELETE", data, headers)
end

--[=[
	Sends an asynchronous PATCH request to the Discord API.
	
	@private
	@method patchAsync
	@param api string -- The API endpoint.
	@param data table -- The data to send with the request.
	@param headers { [string]: string }
	@within Network.DiscordGateway
	@return Vendor.Future -- A Future that resolves with the response.
]=]
function DiscordGateway.Prototype.patchAsync(
	self: DiscordGateway,
	api: string,
	data: any?,
	headers: { [string]: string }?
)
	return self:requestAsync(api, "PATCH", data, headers)
end

--[=[
	
	Sets the cache for a specific API endpoint.
	
	@private
	@method setEndpointCache
	@param endpoint string -- The API endpoint.
	@param cache table -- The cache object.
	@within Network.DiscordGateway
]=]
function DiscordGateway.Prototype.setEndpointCache(self: DiscordGateway, endpoint: string, cache: { [any]: any })
	self.endpointCaches[endpoint] = cache
end

--[=[
	Gets the cache for a specific API endpoint.
	
	@private
	@method getEndpointCache
	@param endpoint string -- The API endpoint.
	@within Network.DiscordGateway
	@return table -- The cache object.
]=]
function DiscordGateway.Prototype.getEndpointCache(self: DiscordGateway, endpoint: string)
	return self.endpointCaches[endpoint]
end

--[=[
	Gets the current Discord API version.
	
	@private
	@method getApiVersion
	@within Network.DiscordGateway
	@return number -- The API version.
]=]
function DiscordGateway.Prototype.getApiVersion(_: DiscordGateway)
	return DISCORD_API_VERSION
end

--[=[
	Creates a new instance of DiscordGateway.
	
	@private
	@function new
	@param discordClient any -- The Discord client object.
	@within Network.DiscordGateway
	@return DiscordGateway -- A new instance of DiscordGateway.
]=]
function DiscordGateway.Interface.new(discordClient: any)
	return Construct({
		discordClient = discordClient,
		discordScheduler = HTTPScheduler.new(1),

		gatewayEventIn = EventIn.new(),

		reporter = Console.new("🌉 DiscordGateway"),

		endpointRateLimits = {} :: { [string]: HTTPRatelimit.HTTPRatelimit },
		endpointCaches = {} :: { [string]: { [any]: any } },
	}, DiscordGateway.Prototype)
end

export type DiscordGateway = typeof(DiscordGateway.Interface.new())

return DiscordGateway.Interface
