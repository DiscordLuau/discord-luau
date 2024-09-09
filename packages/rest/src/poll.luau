local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

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
): future.Future<restTypes.GetAnswerVotersResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam("after", urlParams.after and tostring(urlParams.after) or (nil :: any))
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetAnswerVoters, channelId, messageId, answerId))

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
): future.Future<restTypes.EndPollResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.EndPoll, channelId, messageId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Poll
