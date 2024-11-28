local stdPolyfills = require("../lune_packages/std_polyfills")

local async = require("../lune_packages/async")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/auto-moderation
]]
local AutoModeration = {}

-- https://discord.com/developers/docs/resources/auto-moderation#list-auto-moderation-rules-for-guild
function AutoModeration.listAutoModerationRulesForGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): async.Async<
	apiTypes.ListAutoModerationRulesForGuildResponse
>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ListAutoModerationRulesForGuild, guildId))

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
): async.Async<apiTypes.GetAutoModerationRuleResponse>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetAutoModerationRule, guildId, autoModerationRuleId))

		local status, response = instance:executeAsync():await()

		assert(status == "Fulfilled", tostring(response))

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/auto-moderation#create-auto-moderation-rule
function AutoModeration.createAutoModerationRuleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateAutoModerationRuleRequest,
	auditLogReason: string?
): async.Async<apiTypes.AutomoderationRuleObject>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateAutoModerationRule, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
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
	jsonParams: apiTypes.CreateAutoModerationRuleRequest,
	auditLogReason: string?
): async.Async<apiTypes.AutomoderationRuleObject>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyAutoModerationRule, guildId, autoModerationRuleId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
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
): async.Async<apiTypes.AutomoderationRuleObject>
	return async.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteAutoModerationRule, guildId, autoModerationRuleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		instance:executeAsync():await()
	end)
end

return AutoModeration
