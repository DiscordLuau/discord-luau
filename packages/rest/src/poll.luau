local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/poll
]]
local Poll = {}

-- https://discord.com/developers/docs/resources/poll#get-answer-voters
function Poll.getAnswerVotersAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake,
	answerId: apiTypes.Snowflake,
	urlParams: {
		after: number?,
		limit: number?,
	}
): async.Async<apiTypes.GetAnswerVotersResponse>
	return async.new(function()
		instance:assertToken()

		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetAnswerVoters, channelId, messageId, answerId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/poll#end-poll
function Poll.endPollAsync(
	instance: request.Request,
	channelId: apiTypes.Snowflake,
	messageId: apiTypes.Snowflake
): async.Async<apiTypes.EndPollResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.EndPoll, channelId, messageId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Poll
