local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

--[=[
	@class Rest.auditLog

	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/audit-log
]=]
local auditLog = {}

--[=[
	@within Rest.application

	https://discord.com/developers/docs/resources/audit-log#get-guild-audit-log
]=]
function auditLog.getGuildAuditLogAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		userId: apiTypes.Snowflake?,
		before: apiTypes.Snowflake?,
		after: apiTypes.Snowflake?,
		limit: number?,
		actionType: ActionType,
	}
): future.FutureLike<string, apiTypes.GetGuildAuditLogResponse>
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("user_id", urlParams.userId :: string)
		instance:addUrlParam("before", urlParams.before :: string)
		instance:addUrlParam("after", urlParams.after :: string)
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam(
			"action_type",
			urlParams.actionType and apiTypes.guild.AuditLogEvent[urlParams.actionType] or (nil :: any)
		)

		instance:setMethod("GET")
		instance:setUrl(string.format(apiTypes.rest.endpoints.GetGuildAuditLog, guildId))

		local response = instance:executeAsync():await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().body
	end) :: future.FutureLike<string, apiTypes.GetGuildAuditLogResponse>
end

export type ActionType =
	"GuildUpdate"
	| "ChannelCreate"
	| "ChannelUpdate"
	| "ChannelDelete"
	| "ChannelOverwriteCreate"
	| "ChannelOverwriteUpdate"
	| "ChannelOverwriteDelete"
	| "MemberKick"
	| "MemberPrune"
	| "MemberBanAdd"
	| "MemberBanRemove"
	| "MemberUpdate"
	| "MemberRoleUpdate"
	| "MemberMove"
	| "MemberDisconnect"
	| "BotAdd"
	| "RoleCreate"
	| "RoleUpdate"
	| "RoleDelete"
	| "InviteCreate"
	| "InviteUpdate"
	| "InviteDelete"
	| "WebhookCreate"
	| "WebhookUpdate"
	| "WebhookDelete"
	| "EmojiCreate"
	| "EmojiUpdate"
	| "EmojiDelete"
	| "MessageDelete"
	| "MessageBulkDelete"
	| "MessagePin"
	| "MessageUnpin"
	| "IntegrationCreate"
	| "IntegrationUpdate"
	| "IntegrationDelete"
	| "StageInstanceCreate"
	| "StageInstanceUpdate"
	| "StageInstanceDelete"
	| "StickerCreate"
	| "StickerUpdate"
	| "StickerDelete"
	| "GuildScheduledEventCreate"
	| "GuildScheduledEventUpdate"
	| "GuildScheduledEventDelete"
	| "ThreadCreate"
	| "ThreadUpdate"
	| "ThreadDelete"
	| "ApplicationCommandPermissionUpdate"
	| "AutoModerationRuleCreate"
	| "AutoModerationRuleUpdate"
	| "AutoModerationRuleDelete"
	| "AutoModerationBlockMessage"
	| "AutoModerationFlagToChannel"
	| "AutoModerationUserCommunicationDisabled"

return auditLog
