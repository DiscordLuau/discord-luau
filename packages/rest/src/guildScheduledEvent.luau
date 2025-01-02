local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/guild-scheduled-event
]]
local GuildScheduledEvent = {}

-- https://discord.com/developers/docs/resources/guild-scheduled-event#list-scheduled-events-for-guild
function GuildScheduledEvent.listScheduledEventsForGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		withUserCount: boolean?,
	}
): future.Future<
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

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild-scheduled-event#create-guild-scheduled-event
function GuildScheduledEvent.createGuildScheduledEvent(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateGuildScheduledEventRequest,
	auditLogReason: string?
): future.Future<
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

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event
function GuildScheduledEvent.getScheduledEventsForGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake,
	urlParams: {
		withUserCount: boolean?,
	}
): future.Future<
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

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild-scheduled-event#modify-guild-scheduled-event
function GuildScheduledEvent.modifyGuildScheduledEvent(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake,
	jsonParams: apiTypes.ModifyGuildScheduledEventRequest,
	auditLogReason: string?
): future.Future<
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

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild-scheduled-event#delete-guild-scheduled-event
function GuildScheduledEvent.deleteGuildScheduledEvent(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake
): future.Future<
	string,
	apiTypes.DeleteGuildScheduledEventResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteGuildScheduledEvent, guildId, scheduledEventId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

-- https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event-users
function GuildScheduledEvent.getGuildScheduledEventUsers(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake
): future.Future<
	string,
	apiTypes.GetGuildScheduledEventUsersResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildScheduledEventUsers, guildId, scheduledEventId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), response:unwrapErr())

		return response:unwrapOk().body
	end)
end

return GuildScheduledEvent
