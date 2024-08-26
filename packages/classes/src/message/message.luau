--[[
	Implementation of the Discord Message class in Luau

	https://discord.com/developers/docs/resources/message#message-object
]]

local datetime = require("@std-polyfills/datetime")

local import = require("@utils/import")

local apiTypes = require("@api-types/apiTypes")
local messageTypes = require("@api-types/message")

local user = require("@classes/user")
local role = require("@classes/guild/role")
local channelMention = require("@classes/channels/mention")
local attachment = require("@classes/attachment")
local embed = require("@classes/embed/embed")
local reaction = require("@classes/reaction/reaction")
local activity = require("@classes/message/activity")
local application = require("@classes/application/application")
local reference = require("@classes/message/reference")
local interactionMetadata = require("@classes/message/ineractionMetadata")
local interaction = require("@classes/message/interaction")
local stickerItem = require("@classes/message/stickerItem")
local roleSubscriptionData = require("@classes/message/roleSubscriptionData")
local member = require("@classes/guild/member")
local poll = require("@classes/message/poll/poll")
local call = require("@classes/message/call")
local state = require("@classes/state")

local textInputComponent = require("@classes/message/components/textInput")
local selectMenuComponent = require("@classes/message/components/selectMenu/selectMenu")
local actionRowComponent = require("@classes/message/components/actionRow")
local buttonComponent = require("@classes/message/components/button")

local messageBitflag = require("@classes/bitflags/message")

local Message = {}

Message.Interface = {}
Message.Prototype = {}

function Message.Prototype.sync(self: Message, messageData: apiTypes.MessageObject)
	self.type = (
		messageData.type == 0 and "Default"
		or messageData.type == 1 and "RecipientAdd"
		or messageData.type == 2 and "RecipientRemove"
		or messageData.type == 3 and "Call"
		or messageData.type == 4 and "ChannelNameChange"
		or messageData.type == 5 and "ChannelIconChange"
		or messageData.type == 6 and "ChannelPinnedMessage"
		or messageData.type == 7 and "UserJoin"
		or messageData.type == 8 and "GuildBoost"
		or messageData.type == 9 and "GuildBoostTier1"
		or messageData.type == 10 and "GuildBoostTier2"
		or messageData.type == 11 and "GuildBoostTier3"
		or messageData.type == 12 and "ChannelFollowAdd"
		or messageData.type == 14 and "GuildDiscoveryDisqualified"
		or messageData.type == 15 and "GuildDiscoveryRequalified"
		or messageData.type == 16 and "GuildDiscoveryGracePeriodInitialWarning"
		or messageData.type == 17 and "GuildDiscoveryGracePeriodFinalWarning"
		or messageData.type == 18 and "ThreadCreated"
		or messageData.type == 19 and "Reply"
		or messageData.type == 20 and "ChatInputCommand"
		or messageData.type == 21 and "ThreadStarterMessage"
		or messageData.type == 22 and "GuildInviteReminder"
		or messageData.type == 23 and "ContextMenuCommand"
		or messageData.type == 24 and "AutoModerationAction"
		or messageData.type == 25 and "RoleSubscriptionPurchase"
		or messageData.type == 26 and "InteractionPremiumUpsell"
		or messageData.type == 27 and "StageStart"
		or messageData.type == 28 and "StageEnd"
		or messageData.type == 29 and "StageSpeaker"
		or messageData.type == 31 and "StageTopic"
		or messageData.type == 32 and "GuildApplicationPremiumSubscription"
		or messageData.type == 36 and "GuildIncidentAlertModeEnabled"
		or messageData.type == 37 and "GuildIncidentAlertModeDisabled"
		or messageData.type == 38 and "GuildIncidentReportRaid"
		or messageData.type == 39 and "GuildIncidentReportFalseAlarm"
		or messageData.type == 44 and "PurchaseNotification"
		or messageData.type == 46 and "PollResult"
	) :: messageTypes.MessageType

	local mentionArray = {}
	local roleArray = {}
	local channelMentionArray = {}
	local attachmentArray = {}
	local embedArray = {}
	local reactionArray = {}
	local stickerItemArray = {}

	local componentArray: {
		textInputComponent.TextInput
		| selectMenuComponent.SelectMenu
		| actionRowComponent.ActionRow
		| buttonComponent.Button
	} =
		{}

	for _, stickerData in next, messageData.sticker_items or {} do
		table.insert(stickerItemArray, stickerItem.new(stickerData))
	end

	for _, componentData in next, messageData.components or {} do
		if componentData.type == 1 then
			local data = componentData :: apiTypes.ActionRowComponentObject

			table.insert(componentArray, actionRowComponent.new(data))
		elseif componentData.type == 2 then
			local data = componentData :: apiTypes.ButtonComponentObject

			table.insert(componentArray, buttonComponent.new(data))
		elseif componentData.type == 4 then
			local data = componentData :: apiTypes.TextInputComponentObject

			table.insert(componentArray, textInputComponent.new(data))
		elseif
			componentData.type == 3
			or componentData.type == 5
			or componentData.type == 6
			or componentData.type == 7
			or componentData.type == 8
		then
			local data = componentData :: apiTypes.SelectMenuComponentObject

			table.insert(componentArray, selectMenuComponent.new(data))
		end
	end

	self.id = messageData.id
	self.channelId = messageData.channel_id
	self.author = user.new(messageData.author)
	self.content = messageData.content
	self.timestamp = datetime.fromIsoDate(messageData.timestamp)
	self.tts = messageData.tts
	self.mentionEveryone = messageData.mention_everyone
	self.mentionChannels = mentionArray
	self.mentionRoles = roleArray
	self.mentionChannels = channelMentionArray
	self.attachments = attachmentArray
	self.embeds = embedArray
	self.reactions = reactionArray
	self.nonce = tostring(messageData.nonce)
	self.pinned = messageData.pinned
	self.webhookId = messageData.webhook_id
	self.activity = messageData.activity and activity.new(messageData.activity)
	self.application = messageData.application and application.new(self.state, messageData.application)
	self.applicationId = messageData.application_id
	self.flags = messageData.flags and messageBitflag.new(messageData.flags)
	self.messageReference = messageData.message_reference and reference.new(messageData.message_reference)
	self.referencedMessage = messageData.referenced_message
		and Message.Interface.new(self.state, messageData.referenced_message)
	self.interactionMetadata = messageData.interaction_metadata
		and interactionMetadata.new(messageData.interaction_metadata)
	self.interaction = messageData.interaction and interaction.new(messageData.interaction)
	self.components = componentArray
	self.stickerItems = stickerItemArray
	self.position = messageData.position
	self.roleSubscriptionData = messageData.role_subscription_data
		and roleSubscriptionData.new(messageData.role_subscription_data)
	self.poll = messageData.poll and poll.new(messageData.poll)
	self.call = messageData.call and call.new(messageData.call)

	-- cyclic dependency, can only require during runtime.
	self.resolved = import("@classes/resolved").new(self.state, messageData.resolved)
end

function Message.Interface.new(state: state.State, messageData: apiTypes.MessageObject): Message
	local self = setmetatable(
		{
			state = state,
		} :: Message,
		{ __index = Message.Prototype }
	)

	self:sync(messageData)

	return self
end

export type Message = typeof(Message.Prototype) & {
	state: state.State,

	id: apiTypes.Snowflake,
	channelId: apiTypes.Snowflake?,
	author: user.User,
	content: string,
	timestamp: datetime.DateTime,
	editedTimestamp: datetime.DateTime?,
	tts: boolean,
	mentionEveryone: boolean,
	mentions: { user.User },
	mentionRoles: { role.Role },
	mentionChannels: { channelMention.ChannelMention },
	attachments: { attachment.Attachment },
	embeds: { embed.Embed },
	reactions: { reaction.Reaction },
	nonce: string,
	pinned: boolean,
	webhookId: apiTypes.Snowflake?,
	type: messageTypes.MessageType,
	activity: activity.Activity?,
	application: application.Application?,
	applicationId: apiTypes.Snowflake?,
	flags: messageBitflag.MessageBitflag?,
	messageReference: reference.Reference?,
	-- messageSnapshots: unknown?, -- todo: add support for message snapshots
	referencedMessage: Message?,
	interactionMetadata: interactionMetadata.IneractionMetadata?,
	interaction: interaction.Interaction?,
	-- thread: unknown?, -- fixme: we can't type the channels since channels require this message class.
	components: {
		textInputComponent.TextInput
		| selectMenuComponent.SelectMenu
		| actionRowComponent.ActionRow
		| buttonComponent.Button
	},
	stickerItems: { stickerItem.StickerItem },
	position: number?,
	roleSubscriptionData: roleSubscriptionData.RoleSubscriptionData,
	resolved: {
		state: state.State,

		users: { [apiTypes.Snowflake]: user.User }?,
		members: { [apiTypes.Snowflake]: member.Member }?,
		roles: { [apiTypes.Snowflake]: role.Role },
		-- channels: { [apiTypes.Snowflake]: unknown }, -- fixme: we can't type the channels since channels require this message class.
		messages: { [apiTypes.Snowflake]: Message },
		attachments: { [apiTypes.Snowflake]: attachment.Attachment },
	}?,
	poll: poll.Poll?,
	call: call.Call?,
}

return Message.Interface
