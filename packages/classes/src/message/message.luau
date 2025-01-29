--[[
	Implementation of the Discord Message class in Luau

	https://discord.com/developers/docs/resources/message#message-object
]]

local stdPolyfills = require("../../lune_packages/std_polyfills")

local apiTypes = require("../../lune_packages/api_types")
local future = require("../../luau_packages/future")
local builders = require("../../lune_packages/builders")
local state = require("../../lune_packages/state")
local rest = require("../../lune_packages/rest")

local user = require("../user")
local role = require("../guild/role")
local channelMention = require("../channels/mention")
local attachment = require("../attachment")
local embed = require("../embed/embed")
local reaction = require("../reaction/reaction")
local activity = require("./activity")
local application = require("../application/application")
local reference = require("./reference")
local interactionMetadata = require("./ineractionMetadata")
local interaction = require("./interaction")
local stickerItem = require("./stickerItem")
local roleSubscriptionData = require("./roleSubscriptionData")
local member = require("../guild/member")
local poll = require("./poll/poll")
local call = require("./call")
local messageBitflag = require("../bitflags/message")

local textInputComponent = require("./components/textInput")
local selectMenuComponent = require("./components/selectMenu/selectMenu")
local actionRowComponent = require("./components/actionRow")
local buttonComponent = require("./components/button")

local _require = require :: any

-- https://discord.com/developers/docs/resources/channel#start-thread-from-message

local Message = {}

Message.Interface = {}
Message.Prototype = {}

--[[
	Add a reaction to a message. Requires READ_MESSAGE_HISTORY and ADD_REACTIONS permissions.
]]
function Message.Prototype.addReactionAsync(self: Message, emoji: builders.emojiJSON | string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()
		local emojiObject = emoji :: string

		if type(emoji) == "table" then
			assert(emoji.id, `Reaction must have an id`)
			assert(emoji.name, `Reaction must have a name`)

			emojiObject = `{emoji.name}:{emoji.id}`
		end

		local response = rest.message.createReactionAsync(request, self.channelId, self.id, emojiObject):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Remove the current user's reaction from a message
]]
function Message.Prototype.removeOwnReactionAsync(self: Message, emoji: builders.emojiJSON | string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()
		local emojiObject = emoji :: string

		if type(emoji) == "table" then
			assert(emoji.id, `Reaction must have an id`)
			assert(emoji.name, `Reaction must have a name`)

			emojiObject = `{emoji.name}:{emoji.id}`
		end

		local response = rest.message.deleteOwnReactionAsync(request, self.channelId, self.id, emojiObject):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Remove another user's reaction from a message. Requires MANAGE_MESSAGES permission.
]]
function Message.Prototype.deleteUserReactionAsync(
	self: Message,
	emoji: builders.emojiJSON | string,
	userId: apiTypes.Snowflake
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()
		local emojiObject = emoji :: string

		if type(emoji) == "table" then
			assert(emoji.id, `Reaction must have an id`)
			assert(emoji.name, `Reaction must have a name`)

			emojiObject = `{emoji.name}:{emoji.id}`
		end

		local response =
			rest.message.deleteUserReactionAsync(request, self.channelId, self.id, emojiObject, userId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Get a list of users that reacted with a specific emoji
]]
function Message.Prototype.getReactionsAsync(
	self: Message,
	emoji: builders.emojiJSON | string,
	reactionType: apiTypes.ReactionType?,
	afterUserId: apiTypes.Snowflake?,
	limit: number?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()
		local emojiObject = emoji :: string

		if type(emoji) == "table" then
			assert(emoji.id, `Reaction must have an id`)
			assert(emoji.name, `Reaction must have a name`)

			emojiObject = `{emoji.name}:{emoji.id}`
		end

		local response = rest.message
			.getReactionsAsync(request, self.channelId, self.id, emojiObject, {
				reactionType = reactionType,
				after = afterUserId,
				limit = limit,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local users = {}

		for _, userData in next, response:unwrapOk() do
			table.insert(users, user.new(userData))
		end

		return users :: any
	end) :: future.FutureLike<string, user.User>
end

--[[
	Remove all reactions from a message. Requires MANAGE_MESSAGES permission.
]]
function Message.Prototype.deleteAllReactionsAsync(self: Message)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.message.deleteAllReactionsAsync(request, self.channelId, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Remove all reactions of a specific emoji from a message. Requires MANAGE_MESSAGES permission.
]]
function Message.Prototype.deleteAllReactionsForEmojiAsync(self: Message, emoji: builders.emojiJSON | string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()
		local emojiObject = emoji :: string

		if type(emoji) == "table" then
			assert(emoji.id, `Reaction must have an id`)
			assert(emoji.name, `Reaction must have a name`)

			emojiObject = `{emoji.name}:{emoji.id}`
		end

		local response =
			rest.message.deleteAllReactionsForEmojiAsync(request, self.channelId, self.id, emojiObject):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Edit a message. The current user must be the author of the message.
]]
function Message.Prototype.editMessageAsync(self: Message, message: builders.messageJSON)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.message
			.editMessageAsync(request, self.channelId, self.id, {
				content = message.content,
				embeds = message.embeds,
				components = message.components,
				allowed_mentions = message.allowed_mentions,
				attachments = message.attachments,
				flags = message.flags,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		self:sync(response:unwrapOk())

		return self
	end) :: future.FutureLike<string, Message>
end

--[[
	Delete a message. If operating on a guild channel and trying to delete a message that was not sent by the current user,
	this endpoint requires the MANAGE_MESSAGES permission.
]]
function Message.Prototype.deleteMessageAsync(self: Message, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.message.deleteMessageAsync(request, self.channelId, self.id, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

function Message.Prototype.sync(self: Message, messageData: apiTypes.MessageObject)
	self.type = apiTypes.message.MessageType[messageData.type]

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
	self.timestamp = messageData.timestamp and stdPolyfills.datetime.fromIsoDate(messageData.timestamp)
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
	self.resolved = messageData.resolved and _require("../resolved").new(self.state, messageData.resolved)
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
	timestamp: stdPolyfills.DateTime?,
	editedTimestamp: stdPolyfills.DateTime?,
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
	type: apiTypes.MessageType,
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
