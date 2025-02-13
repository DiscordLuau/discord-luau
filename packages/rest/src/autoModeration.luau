local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/auto-moderation
]]
local AutoModeration = {}

-- https://discord.com/developers/docs/resources/auto-moderation#list-auto-moderation-rules-for-guild
function AutoModeration.listAutoModerationRulesForGuildAsync(instance: request.Request, guildId: apiTypes.Snowflake)
	return future.Future.new(
			function()
				instance:assertToken()

				instance:setMethod("GET")
				instance:setUrl(string.format(apiTypes.rest.endpoints.ListAutoModerationRulesForGuild, guildId))

				local response = instance:executeAsync():await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				return response:unwrapOk().body
			end
		) :: future.FutureLike<string, apiTypes.ListAutoModerationRulesForGuildResponse>
end

-- https://discord.com/developers/docs/resources/auto-moderation#get-auto-moderation-rule
function AutoModeration.getAutoModerationRulesForGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	autoModerationRuleId: apiTypes.Snowflake
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetAutoModerationRule, guildId, autoModerationRuleId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetAutoModerationRuleResponse>
end

-- https://discord.com/developers/docs/resources/auto-moderation#create-auto-moderation-rule
function AutoModeration.createAutoModerationRuleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateAutoModerationRuleRequest,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("POST")
		instance:setUrl(string.format(apiTypes.rest.endpoints.CreateAutoModerationRule, guildId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.CreateAutoModerationRuleResponse>
end

-- https://discord.com/developers/docs/resources/auto-moderation#modify-auto-moderation-rule
function AutoModeration.modifyAutoModerationRuleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	autoModerationRuleId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateAutoModerationRuleRequest,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.ModifyAutoModerationRule, guildId, autoModerationRuleId))
		instance:setBody(stdPolyfills.serde.encode("json", jsonParams, true))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.ModifyAutoModerationRuleResponse>
end

-- https://discord.com/developers/docs/resources/auto-moderation#delete-auto-moderation-rule
function AutoModeration.deleteAutoModerationRuleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	autoModerationRuleId: apiTypes.Snowflake,
	auditLogReason: string?
)
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("PATCH")
		instance:setUrl(string.format(apiTypes.rest.endpoints.DeleteAutoModerationRule, guildId, autoModerationRuleId))
		instance:addHeader("x-audit-log-reason", auditLogReason :: string)

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.DeleteAutoModerationRuleResponse>
end

return AutoModeration
