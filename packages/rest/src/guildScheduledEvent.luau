local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.guildScheduledEvent

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/guild-scheduled-event
]=]
local guildScheduledEvent = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-scheduled-event#list-scheduled-events-for-guild
]=]
function guildScheduledEvent.listScheduledEventsForGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		withUserCount: boolean?,
	}
): future.FutureLike<
	string,
	apiTypes.ListScheduledEventsForGuildResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam(
			"with_user_count",
			urlParams.withUserCount and tostring(urlParams.withUserCount) or (nil :: any)
		)

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListGuildScheduledForEvents, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ListScheduledEventsForGuildResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-scheduled-event#create-guild-scheduled-event
]=]
function guildScheduledEvent.createGuildScheduledEvent(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildScheduledEventRequest,
	auditLogReason: string?
): future.FutureLike<
	string,
	apiTypes.CreateGuildScheduledEventResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateGuildScheduledEvent, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateGuildScheduledEventResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event
]=]
function guildScheduledEvent.getScheduledEventsForGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake,
	urlParams: {
		withUserCount: boolean?,
	}
): future.FutureLike<
	string,
	apiTypes.GetGuildScheduledEventResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam(
			"with_user_count",
			urlParams.withUserCount and tostring(urlParams.withUserCount) or (nil :: any)
		)

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildScheduledEvent, guildId, scheduledEventId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildScheduledEventResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-scheduled-event#modify-guild-scheduled-event
]=]
function guildScheduledEvent.modifyGuildScheduledEvent(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildScheduledEventRequest,
	auditLogReason: string?
): future.FutureLike<
	string,
	apiTypes.ModifyGuildScheduledEventResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyGuildScheduledEvent, guildId, scheduledEventId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyGuildScheduledEventResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-scheduled-event#delete-guild-scheduled-event
]=]
function guildScheduledEvent.deleteGuildScheduledEvent(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.DeleteGuildScheduledEventResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildScheduledEvent, guildId, scheduledEventId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteGuildScheduledEventResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event-users
]=]
function guildScheduledEvent.getGuildScheduledEventUsers(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.GetGuildScheduledEventUsersResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildScheduledEventUsers, guildId, scheduledEventId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildScheduledEventUsersResponse>
end

return guildScheduledEvent
