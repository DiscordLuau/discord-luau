--[[
	Implementation of the Discord Message class in Luau

	https://discord.com/developers/docs/resources/message#message-object
]]

local datetime = require("@std-polyfills/datetime")

local import = require("@utils/import")

local future = require("@vendor/future")

local apiTypes: string = require("@api-types/apiTypes")
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

local emojiBuilder = require("@builders/emoji")
local messageBuilder = require("@builders/message/message")

local messageBitflag = require("@classes/bitflags/message")

local messageRest = require("@rest/message")

local Message = {}

Message.Interface = {}
Message.Prototype = {}

--[[
	Add a reaction to a message. Requires READ_MESSAGE_HISTORY and ADD_REACTIONS permissions.
]]
function Message.Prototype.addReactionAsync(self: Message, emoji: emojiBuilder.JSON): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		assert(emoji.id, `Reaction must have an id`)
		assert(emoji.name, `Reaction must have a name`)

		local status, response =
			messageRest.createReactionAsync(request, self.channelId, self.id, emoji.id, emoji.name):await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

--[[
	Remove the current user's reaction from a message
]]
function Message.Prototype.removeOwnReactionAsync(self: Message, emoji: emojiBuilder.JSON): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		assert(emoji.id, `Reaction must have an id`)
		assert(emoji.name, `Reaction must have a name`)

		local status, response =
			messageRest.deleteOwnReactionAsync(request, self.channelId, self.id, emoji.id, emoji.name):await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

--[[
	Remove another user's reaction from a message. Requires MANAGE_MESSAGES permission.
]]
function Message.Prototype.deleteUserReactionAsync(
	self: Message,
	emoji: emojiBuilder.JSON,
	userId: apiTypes.Snowflake
): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		assert(emoji.id, `Reaction must have an id`)
		assert(emoji.name, `Reaction must have a name`)

		local status, response =
			messageRest.deleteUserReactionAsync(request, self.channelId, self.id, emoji.id, emoji.name, userId):await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

--[[
	Get a list of users that reacted with a specific emoji
]]
function Message.Prototype.getReactionsAsync(
	self: Message,
	emoji: emojiBuilder.JSON,
	reactionType: messageTypes.ReactionType?,
	afterUserId: apiTypes.Snowflake?,
	limit: number?
): future.Future<{ reaction.Reaction }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		assert(emoji.id, `Reaction must have an id`)
		assert(emoji.name, `Reaction must have a name`)

		local status, response = messageRest
			.getReactionsAsync(request, self.channelId, self.id, emoji.id, emoji.name, {
				reactionType = reactionType,
				after = afterUserId,
				limit = limit,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local users = {}

		for _, userData in next, response do
			table.insert(users, user.new(userData))
		end

		return users
	end)
end

--[[
	Remove all reactions from a message. Requires MANAGE_MESSAGES permission.
]]
function Message.Prototype.deleteAllReactionsAsync(self: Message): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = messageRest.deleteAllReactionsAsync(request, self.channelId, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

--[[
	Remove all reactions of a specific emoji from a message. Requires MANAGE_MESSAGES permission.
]]
function Message.Prototype.deleteAllReactionsForEmojiAsync(self: Message, emoji: emojiBuilder.JSON): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		assert(emoji.id, `Reaction must have an id`)
		assert(emoji.name, `Reaction must have a name`)

		local status, response =
			messageRest.deleteAllReactionsForEmojiAsync(request, self.channelId, self.id, emoji.name, emoji.id):await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

--[[
	Edit a message. The current user must be the author of the message.
]]
function Message.Prototype.editMessageAsync(self: Message, message: messageBuilder.JSON): future.Future<Message>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = messageRest
			.editMessageAsync(request, self.channelId, self.id, {
				content = message.content,
				embeds = message.embeds,
				components = message.components,
				allowed_mentions = message.allowed_mentions,
				attachments = message.attachments,
				flags = message.flags,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		self:sync(response)

		return self
	end)
end
--[[
	Delete a message. If operating on a guild channel and trying to delete a message that was not sent by the current user,
	this endpoint requires the MANAGE_MESSAGES permission.
]]
function Message.Prototype.deleteMessageAsync(self: Message, reason: string): future.Future<Message>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = messageRest.deleteMessageAsync(request, self.channelId, self.id, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

function Message.Prototype.sync(self: Message, messageData: apiTypes.MessageObject)
	self.type = messageTypes.MessageType[messageData.type]

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

	self.id = messageData.id :: string
	self.channelId = messageData.channel_id :: string
	self.author = messageData.author and user.new(messageData.author)
	self.content = messageData.content
	self.timestamp = messageData.timestamp and datetime.fromIsoDate(messageData.timestamp)
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
	self.interaction = messageData.interaction and interaction.new(self.state, messageData.interaction)
	self.components = componentArray
	self.stickerItems = stickerItemArray
	self.position = messageData.position
	self.roleSubscriptionData = messageData.role_subscription_data
		and roleSubscriptionData.new(messageData.role_subscription_data)
	self.poll = messageData.poll and poll.new(messageData.poll)
	self.call = messageData.call and call.new(messageData.call)

	-- cyclic dependency, can only require during runtime.
	self.resolved = messageData.resolved and import("@classes/resolved").new(self.state, messageData.resolved)
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
	channelId: apiTypes.Snowflake,
	author: user.User?,
	content: string?,
	timestamp: datetime.DateTime?,
	editedTimestamp: datetime.DateTime?,
	tts: boolean?,
	mentionEveryone: boolean?,
	mentions: { user.User },
	mentionRoles: { role.Role },
	mentionChannels: { channelMention.ChannelMention },
	attachments: { attachment.Attachment },
	embeds: { embed.Embed },
	reactions: { reaction.Reaction },
	nonce: string,
	pinned: boolean?,
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
	roleSubscriptionData: roleSubscriptionData.RoleSubscriptionData?,
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
