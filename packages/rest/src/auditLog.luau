local future = require("../luau_packages/future")
local apiTypes = require("../lune_packages/api_types")

local request = require("./request")

local ACTION_TYPE_MAPPING = table.freeze({
	GuildUpdate = 1,
	ChannelCreate = 10,
	ChannelUpdate = 11,
	ChannelDelete = 12,
	ChannelOverwriteCreate = 13,
	ChannelOverwriteUpdate = 14,
	ChannelOverwriteDelete = 15,
	MemberKick = 20,
	MemberPrune = 21,
	MemberBanAdd = 22,
	MemberBanRemove = 23,
	MemberUpdate = 24,
	MemberRoleUpdate = 25,
	MemberMove = 26,
	MemberDisconnect = 27,
	BotAdd = 28,
	RoleCreate = 30,
	RoleUpdate = 31,
	RoleDelete = 32,
	InviteCreate = 40,
	InviteUpdate = 41,
	InviteDelete = 42,
	WebhookCreate = 50,
	WebhookUpdate = 51,
	WebhookDelete = 52,
	EmojiCreate = 60,
	EmojiUpdate = 61,
	EmojiDelete = 62,
	MessageDelete = 72,
	MessageBulkDelete = 73,
	MessagePin = 74,
	MessageUnpin = 75,
	IntegrationCreate = 80,
	IntegrationUpdate = 81,
	IntegrationDelete = 82,
	StageInstanceCreate = 83,
	StageInstanceUpdate = 84,
	StageInstanceDelete = 85,
	StickerCreate = 90,
	StickerUpdate = 91,
	StickerDelete = 92,
	GuildScheduledEventCreate = 100,
	GuildScheduledEventUpdate = 101,
	GuildScheduledEventDelete = 102,
	ThreadCreate = 110,
	ThreadUpdate = 111,
	ThreadDelete = 112,
	ApplicationCommandPermissionUpdate = 121,
	AutoModerationRuleCreate = 140,
	AutoModerationRuleUpdate = 141,
	AutoModerationRuleDelete = 142,
	AutoModerationBlockMessage = 143,
	AutoModerationFlagToChannel = 144,
	AutoModerationUserCommunicationDisabled = 145,
	CreatorMonetizationRequestCreated = 150,
	CreatorMonetizationTermsAccepted = 151,
})

--[[
	HTTP Rest API implementation for the following Resource:

	- https://discord.com/developers/docs/resources/audit-log
]]
local AuditLog = {}

-- https://discord.com/developers/docs/resources/audit-log#get-guild-audit-log
function AuditLog.getGuildAuditLogAsync(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		userId: apiTypes.Snowflake?,
		before: apiTypes.Snowflake?,
		after: apiTypes.Snowflake?,
		limit: number?,
		actionType: ActionType,
	}
)
	return future.Future.new(function()
		instance:assertToken()

		instance:addUrlParam("user_id", urlParams.userId :: string)
		instance:addUrlParam("before", urlParams.before :: string)
		instance:addUrlParam("after", urlParams.after :: string)
		instance:addUrlParam("limit", urlParams.limit and tostring(urlParams.limit) or (nil :: any))
		instance:addUrlParam(
			"action_type",
			urlParams.actionType and ACTION_TYPE_MAPPING[urlParams.actionType] or (nil :: any)
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

return AuditLog
