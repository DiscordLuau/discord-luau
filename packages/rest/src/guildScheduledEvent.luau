local serde = require("@std-polyfills/serde")

local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

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
	restTypes.ListScheduledEventsForGuildResponse
>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam(
			"with_user_count",
			urlParams.withUserCount and tostring(urlParams.withUserCount) or (nil :: any)
		)

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListGuildScheduledForEvents, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild-scheduled-event#create-guild-scheduled-event
function GuildScheduledEvent.createGuildScheduledEvent(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateGuildScheduledEventRequest,
	auditLogReason: string?
): future.Future<restTypes.CreateGuildScheduledEventResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateGuildScheduledEvent, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
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
): future.Future<restTypes.GetGuildScheduledEventResponse>
	return future.new(function()
		instance:assertToken()

		instance:addUrlParam(
			"with_user_count",
			urlParams.withUserCount and tostring(urlParams.withUserCount) or (nil :: any)
		)

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildScheduledEvent, guildId, scheduledEventId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild-scheduled-event#modify-guild-scheduled-event
function GuildScheduledEvent.modifyGuildScheduledEvent(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake,
	jsonParams: restTypes.ModifyGuildScheduledEventRequest,
	auditLogReason: string?
): future.Future<restTypes.ModifyGuildScheduledEventResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyGuildScheduledEvent, guildId, scheduledEventId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild-scheduled-event#delete-guild-scheduled-event
function GuildScheduledEvent.deleteGuildScheduledEvent(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake
): future.Future<restTypes.DeleteGuildScheduledEventResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("DELETE")
		instance:setUrl(string.format(restEndpoints.DeleteGuildScheduledEvent, guildId, scheduledEventId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/guild-scheduled-event#get-guild-scheduled-event-users
function GuildScheduledEvent.getGuildScheduledEventUsers(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	scheduledEventId: apiTypes.Snowflake
): future.Future<restTypes.GetGuildScheduledEventUsersResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetGuildScheduledEventUsers, guildId, scheduledEventId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", response)

		return response.body
	end)
end

return GuildScheduledEvent
