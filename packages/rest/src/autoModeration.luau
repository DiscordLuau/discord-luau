local serde = require("@std-polyfills/serde")
local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local restEndpoints = require("@api-types/rest/endpoints")
local apiTypes = require("@api-types/apiTypes")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/auto-moderation
]]
local AutoModeration = {}

-- https://discord.com/developers/docs/resources/auto-moderation#list-auto-moderation-rules-for-guild
function AutoModeration.listAutoModerationRulesForGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<
	restTypes.ListAutoModerationRulesForGuildResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListAutoModerationRulesForGuild, guildId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/auto-moderation#get-auto-moderation-rule
function AutoModeration.getAutoModerationRulesForGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	autoModerationRuleId: apiTypes.Snowflake
): future.Future<restTypes.GetAutoModerationRuleResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetAutoModerationRule, guildId, autoModerationRuleId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/auto-moderation#create-auto-moderation-rule
function AutoModeration.createAutoModerationRuleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateAutoModerationRuleRequest,
	auditLogReason: string?
): future.Future<apiTypes.AutomoderationRuleObject>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(restEndpoints.CreateAutoModerationRule, guildId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/auto-moderation#modify-auto-moderation-rule
function AutoModeration.modifyAutoModerationRuleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	autoModerationRuleId: apiTypes.Snowflake,
	jsonParams: restTypes.CreateAutoModerationRuleRequest,
	auditLogReason: string?
): future.Future<apiTypes.AutomoderationRuleObject>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.ModifyAutoModerationRule, guildId, autoModerationRuleId))
		instance:setBody(serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/auto-moderation#delete-auto-moderation-rule
function AutoModeration.deleteAutoModerationRuleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	autoModerationRuleId: apiTypes.Snowflake,
	auditLogReason: string?
): future.Future<apiTypes.AutomoderationRuleObject>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(restEndpoints.DeleteAutoModerationRule, guildId, autoModerationRuleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		instance:executeAsync():await()
	end)
end

return AutoModeration
