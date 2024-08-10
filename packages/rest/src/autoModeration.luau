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
function AutoModeration.listAutoModerationRulesForGuild(
	instance: request.Request,
	guildId: apiTypes.Snowflake
): future.Future<
	restTypes.ListAutoModerationRulesForGuildResponse
>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.ListAutoModerationRulesForGuild, guildId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

-- https://discord.com/developers/docs/resources/auto-moderation#get-auto-moderation-rule
function AutoModeration.getAutoModerationRulesForGuild(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	autoModerationRuleId: apiTypes.Snowflake
): future.Future<restTypes.GetAutoModerationRuleResponse>
	return future.new(function()
		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(string.format(restEndpoints.GetAutoModerationRule, guildId, autoModerationRuleId))

		local response = instance:executeAsync():await()

		return response.body
	end)
end

return AutoModeration
