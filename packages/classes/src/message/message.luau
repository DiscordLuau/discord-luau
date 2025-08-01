--[=[
	@class Classes.Message
	@__index Message.Prototype
	
	Implementation of the Discord Message class in Luau
	
	https://discord.com/developers/docs/resources/message#message-object
]=]

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

local Message = {}

Message.Interface = {}
Message.Prototype = {}

--[=[
	@within Classes.Message
	Creates a new thread from an existing message.
]=]
function Message.Prototype.startThreadAsync(
	self: Message,
	threadName: string,
	autoArchiveDuration: number,
	rateLimitPerUser: number?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		assert(#threadName > 0, `threadName needs to be above 0.`)
		assert(#threadName <= 100, `threadName shouldn't be above 100`)

		local response = rest.channel
			.startThreadFromMessageAsync(request, self.channelId, self.id, {
				name = threadName,
				auto_archive_duration = autoArchiveDuration,
				rate_limit_per_user = rateLimitPerUser,
			})
			:await()

		return response:unwrapOk() :: any
	end) :: future.FutureLike<string, apiTypes.AbstractChannel>
end

--[=[
	@within Classes.Message
	Add a reaction to a message. Requires READ_MESSAGE_HISTORY and ADD_REACTIONS permissions.
]=]
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

--[=[
	@within Classes.Message
	Remove the current user's reaction from a message
]=]
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

--[=[
	@within Classes.Message
	Remove another user's reaction from a message. Requires MANAGE_MESSAGES permission.
]=]
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

--[=[
	@within Classes.Message
	Get a list of users that reacted with a specific emoji
]=]
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

--[=[
	@within Classes.Message
	Remove all reactions from a message. Requires MANAGE_MESSAGES permission.
]=]
function Message.Prototype.deleteAllReactionsAsync(self: Message)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.message.deleteAllReactionsAsync(request, self.channelId, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Message
	Remove all reactions of a specific emoji from a message. Requires MANAGE_MESSAGES permission.
]=]
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

--[=[
	@within Classes.Message
	Edit a message. The current user must be the author of the message.
]=]
function Message.Prototype.editAsync(self: Message, message: builders.messageJSON)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		request:setFlag("FormdataRequest", true)

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

--[=[
	@within Classes.Message
	Delete a message. If operating on a guild channel and trying to delete a message that was not sent by the current user,
	this endpoint requires the MANAGE_MESSAGES permission.
]=]
function Message.Prototype.deleteAsync(self: Message, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.message.deleteMessageAsync(request, self.channelId, self.id, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Message
	Reply to a message by creating a new message that references this one.
]=]
function Message.Prototype.replyAsync(self: Message, message: builders.messageJSON)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		request:setFlag("FormdataRequest", true)

		message.message_reference = {
			type = 0, -- referenced
			message_id = self.id,
			channel_id = self.channelId,
			fail_if_not_exists = false,
		}

		local response = rest.message.createMessageAsync(request, self.channelId, message):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		self.pinned = true

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Message
	Pin this message to the channel. Requires MANAGE_MESSAGES permission.
]=]
function Message.Prototype.pinAsync(self: Message)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.pinMessageAsync(request, self.channelId, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		self.pinned = true

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Message
	Unpin this message from the channel. Requires MANAGE_MESSAGES permission.
]=]
function Message.Prototype.unpinAsync(self: Message)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel.unpinMessageAsync(request, self.channelId, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		self.pinned = false

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Message
	@private
	Synchronizes the message object with the data from the API.
]=]
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

	--[=[
		@prop id string
		@within Classes.Message
		The ID of the message.
	]=]
	self.id = messageData.id :: string

	--[=[
		@prop channelId string
		@within Classes.Message
		The ID of the channel the message was sent in.
	]=]
	self.channelId = messageData.channel_id :: string

	--[=[
		@prop author Classes.User
		@within Classes.Message
		The author of this message.
	]=]
	self.author = messageData.author and user.new(messageData.author)

	--[=[
		@prop content string
		@within Classes.Message
		The content of the message.
	]=]
	self.content = messageData.content

	--[=[
		@prop timestamp DateTime
		@within Classes.Message
		When this message was sent.
	]=]
	self.timestamp = messageData.timestamp and stdPolyfills.datetime.fromIsoDate(messageData.timestamp)

	--[=[
		@prop tts boolean
		@within Classes.Message
		Whether this was a TTS message.
	]=]
	self.tts = messageData.tts

	--[=[
		@prop mentionEveryone boolean
		@within Classes.Message
		Whether this message mentions everyone.
	]=]
	self.mentionEveryone = messageData.mention_everyone

	--[=[
		@prop mentionChannels { Classes.ChannelMention }
		@within Classes.Message
		Channels specifically mentioned in this message.
	]=]
	self.mentionChannels = mentionArray

	--[=[
		@prop mentionRoles { Classes.Role }
		@within Classes.Message
		Roles specifically mentioned in this message.
	]=]
	self.mentionRoles = roleArray

	--[=[
		@prop mentionChannels { Classes.ChannelMention }
		@within Classes.Message
		Channels specifically mentioned in this message.
	]=]
	self.mentionChannels = channelMentionArray

	--[=[
		@prop attachments { Classes.Attachment }
		@within Classes.Message
		Any attachments to the message.
	]=]
	self.attachments = attachmentArray

	--[=[
		@prop embeds { Classes.Embed }
		@within Classes.Message
		Any embedded content in the message.
	]=]
	self.embeds = embedArray

	--[=[
		@prop reactions { Classes.Reaction }
		@within Classes.Message
		Reactions to the message.
	]=]
	self.reactions = reactionArray

	--[=[
		@prop nonce string
		@within Classes.Message
		Used for validating a message was sent.
	]=]
	self.nonce = tostring(messageData.nonce)

	--[=[
		@prop pinned boolean
		@within Classes.Message
		Whether this message is pinned.
	]=]
	self.pinned = messageData.pinned

	--[=[
		@prop webhookId string
		@within Classes.Message
		If the message is generated by a webhook, this is the webhook's ID.
	]=]
	self.webhookId = messageData.webhook_id

	--[=[
		@prop activity Classes.Activity
		@within Classes.Message
		Activity information for Rich Presence messages.
	]=]
	self.activity = messageData.activity and activity.new(messageData.activity)

	--[=[
		@prop application Classes.Application
		@within Classes.Message
		Application information for Rich Presence messages.
	]=]
	self.application = messageData.application and application.new(self.state, messageData.application)

	--[=[
		@prop applicationId string
		@within Classes.Message
		If the message is an Interaction or application-owned webhook, this is the ID of the application.
	]=]
	self.applicationId = messageData.application_id

	--[=[
		@prop flags Classes.MessageBitflag
		@within Classes.Message
		Message flags combined as a bitfield.
	]=]
	self.flags = messageData.flags and messageBitflag.new(messageData.flags)

	--[=[
		@prop messageReference Classes.Reference
		@within Classes.Message
		Reference data for crossposted messages and replies.
	]=]
	self.messageReference = messageData.message_reference and reference.new(messageData.message_reference)

	--[=[
		@prop referencedMessage Classes.Message
		@within Classes.Message
		The message that was referenced in a reply.
	]=]
	self.referencedMessage = messageData.referenced_message
		and Message.Interface.new(self.state, messageData.referenced_message)

	--[=[
		@prop interactionMetadata Classes.IneractionMetadata
		@within Classes.Message
		Metadata for interaction messages.
	]=]
	self.interactionMetadata = messageData.interaction_metadata
		and interactionMetadata.new(messageData.interaction_metadata)

	--[=[
		@prop interaction Classes.Interaction
		@within Classes.Message
		Interaction information if the message is a response to an Interaction.
	]=]
	self.interaction = messageData.interaction and interaction.new(self.state, messageData.interaction)

	--[=[
		@prop components { Classes.TextInput | Classes.SelectMenu | Classes.ActionRow | Classes.Button }
		@within Classes.Message
		Components attached to the message.
	]=]
	self.components = componentArray

	--[=[
		@prop stickerItems { Classes.StickerItem }
		@within Classes.Message
		Stickers attached to the message.
	]=]
	self.stickerItems = stickerItemArray

	--[=[
		@prop position number
		@within Classes.Message
		Position of the message in a thread.
	]=]
	self.position = messageData.position

	--[=[
		@prop roleSubscriptionData Classes.RoleSubscriptionData
		@within Classes.Message
		Data for role subscription purchase or renewal notifications.
	]=]
	self.roleSubscriptionData = messageData.role_subscription_data
		and roleSubscriptionData.new(messageData.role_subscription_data)

	--[=[
		@prop poll Classes.Poll
		@within Classes.Message
		Poll attached to the message.
	]=]
	self.poll = messageData.poll and poll.new(messageData.poll)

	--[=[
		@prop call Classes.Call
		@within Classes.Message
		Call information if this message started a call.
	]=]
	self.call = messageData.call and call.new(messageData.call)

	-- cyclic dependency, can only require during runtime.
	--[=[
		@prop resolved table
		@within Classes.Message
		Resolved objects from the interaction data.
	]=]
	self.resolved = messageData.resolved and _require("../resolved").new(self.state, messageData.resolved)
end

--[=[
	@private
	@within Classes.Message
	Creates a new Message instance with the specified message data.
]=]
function Message.Interface.new(state: state.State, messageData: apiTypes.MessageObject): Message
	local self = setmetatable(
		{
			--[=[
				@prop state State
				The state object for this message.
			]=]
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
