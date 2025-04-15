--[=[
	@class State.Rest
	@__index Prototype

	REST represents an interface to manipulate the Discord REST API.
	When making any sort of REST request, this class is used so that we accurately
	track the rate limits and add the token to each request.
]=]

--[=[
	@prop token Secret
	@within State.Rest
]=]

--[=[
	@prop logger Logger
	@within State.Rest
]=]

--[=[
	@prop routeRatelimits { [string]: { remaining: number, limit: number, resetAfter: number, cooloff: boolean? } }
	@within State.Rest
]=]

--[=[
	@prop routeBuckets { [string]: string? }
	@within State.Rest
]=]

--[=[
	@prop globalRequestCount number
	@within State.Rest
]=]

--[=[
	@prop globalRatelimit number
	@within State.Rest
]=]

--[=[
	@prop isBlocked boolean
	@within State.Rest
]=]

--[=[
	@prop resourcesBlocked { [string]: boolean? }
	@within State.Rest
]=]

--[=[
	@prop intents number
	@within State.Rest
]=]

--[=[
	@prop version number
	@within State.Rest
]=]

local secret = require("../luau_packages/secret")
local formdata = require("../luau_packages/formdata")
local stdPolyfills = require("../lune_packages/std_polyfills")
local utils = require("../lune_packages/utils")
local rest = require("../lune_packages/rest")
local logger = require("../lune_packages/logger")

local PER_RESOURCE_COOLOFF_TIME = 1
local WARN_AFTER = 5

local REST = {}

REST.Interface = {}
REST.Prototype = {}

--[=[
	@within State.Rest

	Quality of life method to yield, warn after a specific duration, and resume once a condition has been met
]=]
function REST.Prototype.yieldUntil(self: REST, callback: () -> boolean, message: string)
	local timeDelayed = 0
	local hasWarned = false

	while not callback() do
		timeDelayed += stdPolyfills.task.wait(0.5)

		if timeDelayed > WARN_AFTER and not hasWarned then
			hasWarned = true

			self.logger:warn(message)
		end
	end
end

--[=[
	@within State.Rest

	Adds per-route bucket rate limit handling for each request.
]=]
function REST.Prototype.implementBucketRatelimitsFor(self: REST, request: rest.Request)
	request:addHook("BeforeRequest", function(requestInfo)
		local requestHash = `{requestInfo.method}@{requestInfo.url}`
		local bucketId = self.routeBuckets[requestHash]

		if bucketId then
			local bucket = self.routeRatelimits[bucketId]

			if not bucket then
				return true
			end

			self:yieldUntil(function()
				return (bucket.remaining > 0 and bucket.cooloff ~= true) :: boolean
			end, `please wait - {requestHash} has been ratelimited by bucket id..`)

			if bucket then
				bucket.remaining = bucket.remaining - 1
				bucket.cooloff = true

				stdPolyfills.task.delay(PER_RESOURCE_COOLOFF_TIME, function()
					bucket.cooloff = nil
				end)
			end
		end

		return true
	end)

	request:addHook("AfterRequest", function(requestInfo, data)
		assert(data, `Expected 'data'`)

		local ratelimitBucket = data.headers["x-ratelimit-bucket"] :: string
		local ratelimitRemaining = data.headers["x-ratelimit-remaining"] :: string
		local ratelimitResetAfter = data.headers["x-ratelimit-reset-after"] :: string
		local ratelimitLimit = data.headers["x-ratelimit-limit"] :: string

		local requestHash = `{requestInfo.method}@{requestInfo.url}`

		if not self.routeBuckets[requestHash] then
			self.routeBuckets[requestHash] = ratelimitBucket
		end

		if ratelimitBucket then
			self.routeRatelimits[ratelimitBucket] = {
				remaining = tonumber(ratelimitRemaining) :: number,
				limit = tonumber(ratelimitLimit) :: number,
				resetAfter = tonumber(ratelimitResetAfter) :: number,
			}

			utils.coroutineRun(function()
				stdPolyfills.task.wait(self.routeRatelimits[ratelimitBucket].resetAfter)
				self.routeRatelimits[ratelimitBucket].remaining = self.routeRatelimits[ratelimitBucket].limit
			end)
		end

		return true
	end)
end

--[=[
	@within State.Rest

	Adds global ratelimiting to application
]=]
function REST.Prototype.implementGlobalRatelimitsFor(self: REST, request: rest.Request)
	request:addHook("BeforeRequest", function(requestInfo)
		local requestHash = `{requestInfo.method}@{requestInfo.url}`

		self:yieldUntil(function()
			return self.globalRequestCount + 1 <= self.globalRatelimit
		end, `please wait - {requestHash} has been ratelimited by global resource..`)

		self:yieldUntil(function()
			return not self.isBlocked
		end, `please wait - {requestHash} has been ratelimited by global/user resource..`)

		self:yieldUntil(function()
			return not self.resourcesBlocked[requestInfo.requestUrl]
		end, `please wait - {requestHash} has been ratelimited by shared resource..`)

		self.globalRequestCount += 1

		stdPolyfills.task.delay(1, function()
			self.globalRequestCount -= 1
		end)

		return true
	end)
end

--[=[
	@within State.Rest

	Responsible for handling errors that occur when a request has been sent to discord
]=]
function REST.Prototype.implementErrorHandlerFor(self: REST, request: rest.Request)
	request:addHook("AfterRequest", function(requestInfo, data)
		assert(data, `Expected request data`)

		local success = true
		local message

		if data.statusCode == 429 then
			local decodeSuccess, decodedBody = pcall(stdPolyfills.serde.decode, "json" :: "json", request.body)
			local scope = data.headers["x-ratelimit-scope"] :: string

			assert(decodeSuccess, `Failed to decode JSON value for ratelimit`)

			success = false
			message = decodedBody.message

			if (scope == "user" or scope == "global") or decodedBody.global then
				self.isBlocked = true
			else
				self.resourcesBlocked[requestInfo.requestUrl] = true
			end

			stdPolyfills.task.delay(decodedBody.retry_after, function()
				if (scope == "user" or scope == "global") or decodedBody.global then
					self.isBlocked = false
				else
					self.resourcesBlocked[requestInfo.requestUrl] = false
				end
			end)
		elseif data.statusCode == 403 then
			success = false
			message = `Missing permissions - 403`
		elseif data.statusCode == 401 then
			success = false
			message = `Missing authorization - 401`
		end

		return success, message
	end)
end

--[=[
	@within State.Rest

	Responsible for handling errors that occur when a request has been sent to discord
]=]
function REST.Prototype.implementAttachmentHandlerFor(_: REST, request: rest.Request)
	request:addHook("BeforeRequest", function(requestInfo)
		if request.flags["FormdataRequest"] then
			local bodyJson = stdPolyfills.serde.decode("json", requestInfo.body)
			local messageJson = (bodyJson.data and bodyJson.data or bodyJson) :: {
				attachments: { Attachment }?,
			}

			if messageJson.attachments and #messageJson.attachments > 0 then
				local attachments = table.clone(messageJson.attachments)
				local formdata = formdata.new()

				messageJson.attachments = nil

				formdata:set("payload_json", stdPolyfills.serde.encode("json", messageJson, true), nil, "json")

				for index, attachment in attachments do
					formdata:set(`files[{index - 1}]`, attachment.content, attachment.filename or utils.createGuid())
				end

				requestInfo.headers["content-type"] = `multipart/form-data; boundary={formdata:getHeader()}`

				warn({
					url = requestInfo.url,
					method = requestInfo.method,
					body = formdata:getBody(),
					headers = requestInfo.headers,
				})

				return true,
					{
						url = requestInfo.url,
						method = requestInfo.method,
						body = formdata:getBody(),
						headers = requestInfo.headers,
					}
			end
		end

		return true,
			{
				url = requestInfo.url,
				method = requestInfo.method,
				body = requestInfo.body,
				headers = requestInfo.headers,
			}
	end)
end

--[=[
	@within State.Rest

	Will create a new Request
]=]
function REST.Prototype.newRequest(self: REST): rest.Request
	local newRequest = rest.request.new({
		token = self.token.value,
		restApiVersion = self.version,
	})

	self:implementBucketRatelimitsFor(newRequest)
	self:implementGlobalRatelimitsFor(newRequest)
	self:implementErrorHandlerFor(newRequest)

	self:implementAttachmentHandlerFor(newRequest)

	return newRequest
end

--[=[
	@within State.Rest

	Will create a new REST object
]=]
function REST.Interface.new(settings: {
	token: secret.Secret<string>,
	intents: number,
	version: number,
	globalRatelimit: number,
	logLevel: logger.LogLevel?,
}): REST
	local self = setmetatable(
		{
			token = settings.token,
			logger = logger.new(`REST`, settings.logLevel),
			routeBuckets = {},
			routeRatelimits = {},
			globalRequestCount = 0,
			globalRatelimit = settings.globalRatelimit,
			isBlocked = false,
			resourcesBlocked = {},
			intents = settings.intents,
			version = settings.version,
		} :: REST,
		{
			__index = REST.Prototype,
		}
	)

	return self
end

export type Attachment = {
	content: string,
	filename: string?,
}

export type Bucket = string
export type Ratelimit = { remaining: number, limit: number, resetAfter: number, cooloff: boolean? }
export type REST = typeof(REST.Prototype) & {
	token: secret.Secret<string>,
	logger: logger.Logger,
	routeRatelimits: { [Bucket]: Ratelimit },
	routeBuckets: { [string]: Bucket? },
	globalRequestCount: number,
	globalRatelimit: number,
	isBlocked: boolean,
	resourcesBlocked: { [string]: boolean? },
	intents: number,
	version: number,
}

return REST.Interface
