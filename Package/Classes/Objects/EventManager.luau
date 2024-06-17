local Signal = require("@Vendor/Signal")

local Construct = require("@Utils/Construct")

local DiscordMessage = require("@Objects/DiscordMessage")
local DiscordChannel = require("@Objects/DiscordChannel")

local DiscordUser = require("@Objects/DiscordUser")
local DiscordGuild = require("@Objects/DiscordGuild")
local DiscordGuildMember = require("@Objects/DiscordGuildMember")

local DiscordInteraction = require("@Objects/DiscordInteraction")

local DiscordEvents = require("@Enums/DiscordEvents")

--[=[
	@class Objects.EventManager

	EventManager is responsible for handling Discord events and emitting signals 
	for various Discord activities such as message events, channel events, user updates, 
	guild events, and interactions.
]=]
local EventManager = {}

EventManager.Prototype = {}
EventManager.Interface = {}

EventManager.Prototype.type = "EventManager"

--[=[
	
	Creates a new instance of EventManager and connects it to the provided Discord client.
	
	@function new
	@param discordClient any -- The Discord client instance to connect with the EventManager.
	@within Objects.EventManager
	@return EventManager -- A new instance of EventManager.
]=]
function EventManager.Interface.new(discordClient): EventManager
	local self = Construct({
		--[=[
			@prop onReady Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when the Discord client is ready.
		]=]
		onReady = Signal.new(),

		--[=[
			@prop onMessage Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a new message is received.
			@param message DiscordMessage -- The message received.
		]=]
		onMessage = Signal.new(),

		--[=[
			@prop onMessageChanged Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a message is edited.
			@param message DiscordMessage -- The message that was edited.
		]=]
		onMessageChanged = Signal.new(),

		--[=[
			@prop onMessageDeleted Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a message is deleted.
			@param message DiscordMessage -- The message that was deleted.
		]=]
		onMessageDeleted = Signal.new(),

		--[=[
			@prop onMessageBulkDeleted Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when multiple messages are deleted.
			@param data table -- The data containing channelId, guildId, and ids of deleted messages.
		]=]
		onMessageBulkDeleted = Signal.new(),

		--[=[
			@prop onChannelCreate Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a new channel is created.
			@param channel DiscordChannel -- The channel created.
		]=]
		onChannelCreate = Signal.new(),

		--[=[
			@prop onChannelUpdate Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a channel is updated.
			@param channel DiscordChannel -- The channel that was updated.
		]=]
		onChannelUpdate = Signal.new(),

		--[=[
			@prop onChannelDelete Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a channel is deleted.
			@param channel DiscordChannel -- The channel that was deleted.
		]=]
		onChannelDelete = Signal.new(),

		--[=[
			@prop onUserUpdated Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a user is updated.
			@param user DiscordUser -- The user that was updated.
		]=]
		onUserUpdated = Signal.new(),

		--[=[
			@prop onChannelPinsUpdate Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a channel's pins are updated.
			@param data table -- The data containing guildId, channelId, and lastPinTimestamp.
		]=]
		onChannelPinsUpdate = Signal.new(),

		--[=[
			@prop onGuildCreate Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a new guild is created.
			@param guild DiscordGuild -- The guild created.
		]=]
		onGuildCreate = Signal.new(),

		--[=[
			@prop onGuildUpdate Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a guild is updated.
			@param guild DiscordGuild -- The guild that was updated.
		]=]
		onGuildUpdate = Signal.new(),

		--[=[
			@prop onGuildDelete Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a guild is deleted.
			@param guild DiscordGuild -- The guild that was deleted.
		]=]
		onGuildDelete = Signal.new(),

		--[=[
			@prop onGuildMemberBanned Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a guild member is banned.
			@param data table -- The data containing guildId and user.
		]=]
		onGuildMemberBanned = Signal.new(),

		--[=[
			@prop onGuildMemberUnbanned Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a guild member is unbanned.
			@param data table -- The data containing guildId and user.
		]=]
		onGuildMemberUnbanned = Signal.new(),

		--[=[
			@prop onGuildMemberJoined Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a new member joins a guild.
			@param member DiscordGuildMember -- The member that joined.
		]=]
		onGuildMemberJoined = Signal.new(),

		--[=[
			@prop onGuildMemberLeft Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a member leaves a guild.
			@param data table -- The data containing guildId and user.
		]=]
		onGuildMemberLeft = Signal.new(),

		--[=[
			@prop onGuildMemberUpdated Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when a guild member is updated.
			@param data table -- The data containing guildId, roles, user, nick, avatar, joinedAt, premiumSince, deaf, mute, pending, and communicationDisabledUntil.
		]=]
		onGuildMemberUpdated = Signal.new(),

		--[=[
			@prop onInteraction Vendor.Signal<>
			@within Objects.EventManager
			@tag Event

			Fires when an interaction occurs.
			@param interaction DiscordInteraction -- The interaction that occurred.
		]=]
		onInteraction = Signal.new(),
	}, EventManager.Prototype)

	discordClient.onEvent:connect(function(eventName: DiscordEvents.DiscordEvents, ...)
		if eventName == DiscordEvents.Ready then
			self.onReady:fire(...)
		elseif eventName == DiscordEvents.Message then
			self.onMessage:fire(...)
		elseif eventName == DiscordEvents.MessageChanged then
			self.onMessageChanged:fire(...)
		elseif eventName == DiscordEvents.MessageDeleted then
			self.onMessageDeleted:fire(...)
		elseif eventName == DiscordEvents.MessageBulkDeleted then
			self.onMessageBulkDeleted:fire(...)
		elseif eventName == DiscordEvents.ChannelCreate then
			self.onChannelCreate:fire(...)
		elseif eventName == DiscordEvents.ChannelUpdate then
			self.onChannelUpdate:fire(...)
		elseif eventName == DiscordEvents.ChannelDelete then
			self.onChannelDelete:fire(...)
		elseif eventName == DiscordEvents.UserUpdated then
			self.onUserUpdated:fire(...)
		elseif eventName == DiscordEvents.ChannelPinsUpdate then
			self.onChannelPinsUpdate:fire(...)
		elseif eventName == DiscordEvents.GuildCreate then
			self.onGuildCreate:fire(...)
		elseif eventName == DiscordEvents.GuildUpdate then
			self.onGuildUpdate:fire(...)
		elseif eventName == DiscordEvents.GuildDelete then
			self.onGuildDelete:fire(...)
		elseif eventName == DiscordEvents.GuildMemberBanned then
			self.onGuildMemberBanned:fire(...)
		elseif eventName == DiscordEvents.GuildMemberUnbanned then
			self.onGuildMemberUnbanned:fire(...)
		elseif eventName == DiscordEvents.GuildMemberJoined then
			self.onGuildMemberJoined:fire(...)
		elseif eventName == DiscordEvents.GuildMemberLeft then
			self.onGuildMemberLeft:fire(...)
		elseif eventName == DiscordEvents.GuildMemberUpdated then
			self.onGuildMemberUpdated:fire(...)
		elseif eventName == DiscordEvents.Interaction then
			self.onInteraction:fire(...)
		end
	end)

	return self :: any
end

export type EventManager = typeof(EventManager.Prototype) & {
	onReady: Signal.Signal<nil>,

	onMessage: Signal.Signal<DiscordMessage.DiscordMessage>,
	onMessageChanged: Signal.Signal<DiscordMessage.DiscordMessage>,
	onMessageDeleted: Signal.Signal<DiscordMessage.DiscordMessage>,
	onMessageBulkDeleted: Signal.Signal<{ channelId: string, guildId: string, ids: { string } }>,

	onChannelCreate: Signal.Signal<DiscordChannel.DiscordChannel>,
	onChannelUpdate: Signal.Signal<DiscordChannel.DiscordChannel>,
	onChannelDelete: Signal.Signal<DiscordChannel.DiscordChannel>,

	onUserUpdated: Signal.Signal<DiscordUser.DiscordUser>,

	onChannelPinsUpdate: Signal.Signal<{ guildId: string, channelId: string, lastPinTimestamp: string }>,

	onGuildCreate: Signal.Signal<DiscordGuild.DiscordGuild>,
	onGuildUpdate: Signal.Signal<DiscordGuild.DiscordGuild>,
	onGuildDelete: Signal.Signal<DiscordGuild.DiscordGuild>,

	onGuildMemberBanned: Signal.Signal<{ guildId: string, user: DiscordUser.DiscordUser }>,
	onGuildMemberUnbanned: Signal.Signal<{ guildId: string, user: DiscordUser.DiscordUser }>,

	onGuildMemberJoined: Signal.Signal<DiscordGuildMember.DiscordGuildMember & { guildId: string }>,
	onGuildMemberLeft: Signal.Signal<{ guildId: string, user: DiscordUser.DiscordUser }>,
	onGuildMemberUpdated: Signal.Signal<{
		guildId: string,
		roles: { string },
		user: DiscordUser.DiscordUser,
		nick: string?,
		avatar: string,
		joinedAt: string,
		premiumSince: string,
		deaf: boolean?,
		mute: boolean?,
		pending: boolean?,
		communicationDisabledUntil: string?,
	}>,

	onInteraction: Signal.Signal<DiscordInteraction.DiscordInteraction>,
}

return EventManager.Interface
