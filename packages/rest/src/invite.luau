local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.invite

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/invite
]=]
local invite = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/invite#get-invite
]=]
function invite.getInviteAsync(
	instance: request.Request,
	inviteCode: string,
	urlParams: {
		withCounts: number?,
		withExpiration: boolean?,
		guildScheduledEventId: apiTypes.Snowflake?,
	}
): future.FutureLike<string, apiTypes.GetInviteResponse>
	return future.Future.new(function()
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

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetInviteResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/invite#delete-invite
]=]
function invite.deleteInviteAsync(
	instance: request.Request,
	inviteCode: string,
	auditLogReason: string?
): future.FutureLike<string, apiTypes.DeleteInviteResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteInvite, inviteCode))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteInviteResponse>
end

return invite
