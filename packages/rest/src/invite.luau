local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

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
): async.Async<apiTypes.GetInviteResponse>
	return async.new(function()
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
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetInvite, inviteCode))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/invite#delete-invite
function Invite.deleteInviteAsync(
	instance: request.Request,
	inviteCode: string,
	auditLogReason: string?
): async.Async<apiTypes.GetInviteResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteInvite, inviteCode))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

return Invite
