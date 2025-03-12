local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.poll

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/poll
]=]
local poll = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/poll#get-answer-voters
]=]
function poll.getAnswerVotersAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	answerId: apiTypes.Snowflake,
	urlParams: {
		after: number?,
		limit: number?,
	}
): future.FutureLike<string, apiTypes.GetAnswerVotersResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetAnswerVoters, channelId, messageId, answerId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetAnswerVotersResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/poll#end-poll
]=]
function poll.endPollAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake
): future.FutureLike<string, apiTypes.EndPollResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EndPoll, channelId, messageId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.EndPollResponse>
end

return poll
