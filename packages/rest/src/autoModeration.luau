local stdPolyfills = require("../lune_packages/std_polyfills")

local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.autoModeration

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/auto-moderation
]=]
local autoModeration = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/auto-moderation#list-auto-moderation-rules-for-guild
]=]
function autoModeration.listAutoModerationRulesForGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.ListAutoModerationRulesForGuildResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/auto-moderation#get-auto-moderation-rule
]=]
function autoModeration.getAutoModerationRuleForGuildAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	autoModerationRuleId: apiTypes.Snowflake
): future.FutureLike<
	string,
	apiTypes.GetAutoModerationRuleResponse
>
	return future.Future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetAutoModerationRule, guildId, autoModerationRuleId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetAutoModerationRuleResponse>
end

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/auto-moderation#create-auto-moderation-rule
]=]
function autoModeration.createAutoModerationRuleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateAutoModerationRuleRequest,
	auditLogReason: string?
): future.FutureLike<
	string,
	apiTypes.CreateAutoModerationRuleResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/auto-moderation#modify-auto-moderation-rule
]=]
function autoModeration.modifyAutoModerationRuleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	autoModerationRuleId: apiTypes.Snowflake,
	jsonParams: apiTypes.CreateAutoModerationRuleRequest,
	auditLogReason: string?
): future.FutureLike<
	string,
	apiTypes.ModifyAutoModerationRuleResponse
>
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

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/auto-moderation#delete-auto-moderation-rule
]=]
function autoModeration.deleteAutoModerationRuleAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	autoModerationRuleId: apiTypes.Snowflake,
	auditLogReason: string?
): future.FutureLike<
	string,
	apiTypes.DeleteAutoModerationRuleResponse
>
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

return autoModeration
