local stdPolyfills = require("../luau_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../luau_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.invite

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/invite
]=]
local invite = {}

--[=[
	@within Rest.invite

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

		assert(response:isOk(), `{response:unwrapErr()}`)

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetInviteResponse>
end

--[=[
	@within Rest.invite

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

		assert(response:isOk(), `{response:unwrapErr()}`)

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteInviteResponse>
end

--[=[
	@within Rest.invite

	https://docs.discord.com/developers/resources/invite#get-target-users
]=]
function invite.getInviteTargetUsersAsync(
	instance: request.Request,
	inviteCode: string
): future.FutureLike<string, apiTypes.GetInviteTargetUsersResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetInviteTargetUsers, inviteCode))

		local response = instance:executeAsync():await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetInviteTargetUsersResponse>
end

--[=[
	@within Rest.invite

	https://docs.discord.com/developers/resources/invite#update-target-users
]=]
function invite.updateInviteTargetUsersAsync(
	instance: request.Request,
	inviteCode: string,
	csvContent: string
): future.FutureLike<string, apiTypes.UpdateInviteTargetUsersResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setFlag("FormdataRequest", true)
		instance:setMethod("PUT")
		instance:setUrl(string.format(apiTypes.rest.endpoints.UpdateInviteTargetUsers, inviteCode))
		instance:setBody(stdPolyfills.serde.encode("json", {
			formdata_files = {
				{ name = "target_users_file", content = csvContent, filename = "users.csv" },
			},
		}, true))

		local response = instance:executeAsync():await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.UpdateInviteTargetUsersResponse>
end

--[=[
	@within Rest.invite

	https://docs.discord.com/developers/resources/invite#get-target-users-job-status
]=]
function invite.getInviteTargetUsersJobStatusAsync(
	instance: request.Request,
	inviteCode: string
): future.FutureLike<string, apiTypes.GetInviteTargetUsersJobStatusResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetInviteTargetUsersJobStatus, inviteCode))

		local response = instance:executeAsync():await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetInviteTargetUsersJobStatusResponse>
end

return invite
