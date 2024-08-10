local request = require("@rest/request")
local future = require("@vendor/future")

local restTypes = require("@api-types/rest/types")
local apiTypes = require("@api-types/apiTypes")
local restEndpoints = require("@api-types/rest/endpoints")

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
function AuditLog.getGuildAuditLog(
	instance: request.Request,
	guildId: apiTypes.Snowflake,
	urlParams: {
		userId: apiTypes.Snowflake?,
		before: apiTypes.Snowflake?,
		after: apiTypes.Snowflake?,
		limit: number?,
		actionType: ActionType,
	}
): future.Future<restTypes.GetGuildAuditLogResponse>
	return future.new(function()
		local baseUrl = string.format(restEndpoints.GetGuildAuditLog, guildId)

		if next(urlParams) then
			baseUrl ..= "&"

			for _, value in urlParams do
				if value == urlParams.userId then
					baseUrl ..= `user_id={value}?`
				elseif value == urlParams.before then
					baseUrl ..= `before={value}?`
				elseif value == urlParams.after then
					baseUrl ..= `after={value}?`
				elseif value == urlParams.limit then
					baseUrl ..= `limit={value}?`
				elseif value == urlParams.actionType then
					local actionTypeValue = ACTION_TYPE_MAPPING[value]

					assert(actionTypeValue, `Invalid action type: {value}`)

					baseUrl ..= `action_type={actionTypeValue}?`
				end
			end

			-- remove the last '?'
			baseUrl = string.sub(baseUrl, 1, #baseUrl - 1)
		end

		instance:assertToken()

		instance:setMethod("GET")
		instance:setUrl(baseUrl)

		local response = instance:executeAsync():await()

		return response.body
	end)
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
