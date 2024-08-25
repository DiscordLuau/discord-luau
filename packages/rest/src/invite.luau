local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/invite
]]
local Invite = {}

-- https://discord.com/developers/docs/resources/invite#get-invite
function Invite.getInviteAsync(
	instance: request.Request,
	inviteCode: string,
	urlParams: {
		withCounts: number?,
		withExpiration: boolean?,
		guildScheduledEventId: apiTypes.Snowflake?,
	}
): future.Future<restTypes.GetInviteResponse>
	return future.new(function()
		instance:addUrlParam("with_counts", urlParams.withCounts and tostring(urlParams.withCounts) or (nil :: any))
		instance:addUrlParam(
			"with_expiration",
			urlParams.withExpiration and tostring(urlParams.withExpiration) or (nil :: any)
		)
		instance:addUrlParam(
			"guild_scheduled_event_id",
			urlParams.guildScheduledEventId and tostring(urlParams.guildScheduledEventId) or (nil :: any)
		)

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetInvite, inviteCode))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/invite#delete-invite
function Invite.deleteInviteAsync(
	instance: request.Request,
	inviteCode: string,
	auditLogReason: string?
): future.Future<restTypes.GetInviteResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteInvite, inviteCode))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

return Invite
