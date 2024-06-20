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
		]=]
		onReady = Signal.new(),

		--[=[
			@prop onMessage Vendor.Signal<Objects.DiscordMessage>
			@within Objects.EventManager
		]=]
		onMessage = Signal.new(),

		--[=[
			@prop onMessageChanged Vendor.Signal<Objects.DiscordMessage>
			@within Objects.EventManager
		]=]
		onMessageChanged = Signal.new(),

		--[=[
			@prop onMessageDeleted Vendor.Signal<Objects.DiscordMessage>
			@within Objects.EventManager
		]=]
		onMessageDeleted = Signal.new(),

		--[=[
			@prop onMessageBulkDeleted Vendor.Signal<{ channelId: string, guildId: string, ids: { string } }>
			@within Objects.EventManager
		]=]
		onMessageBulkDeleted = Signal.new(),

		--[=[
			@prop onChannelCreate Vendor.Signal<Objects.DiscordChannel>
			@within Objects.EventManager
		]=]
		onChannelCreate = Signal.new(),

		--[=[
			@prop onChannelUpdate Vendor.Signal<Objects.DiscordChannel>
			@within Objects.EventManager
		]=]
		onChannelUpdate = Signal.new(),

		--[=[
			@prop onChannelDelete Vendor.Signal<Objects.DiscordChannel>
			@within Objects.EventManager
		]=]
		onChannelDelete = Signal.new(),

		--[=[
			@prop onUserUpdated Vendor.Signal<Objects.DiscordUser>
			@within Objects.EventManager
		]=]
		onUserUpdated = Signal.new(),

		--[=[
			@prop onChannelPinsUpdate Vendor.Signal<{ guildId: string, channelId: string, lastPinTimestamp: string }>
			@within Objects.EventManager
		]=]
		onChannelPinsUpdate = Signal.new(),

		--[=[
			@prop onGuildCreate Vendor.Signal<Objects.DiscordGuild>
			@within Objects.EventManager
		]=]
		onGuildCreate = Signal.new(),

		--[=[
			@prop onGuildUpdate Vendor.Signal<Objects.DiscordGuild>
			@within Objects.EventManager
		]=]
		onGuildUpdate = Signal.new(),

		--[=[
			@prop onGuildDelete Vendor.Signal<Objects.DiscordGuild>
			@within Objects.EventManager
		]=]
		onGuildDelete = Signal.new(),

		--[=[
			@prop onGuildMemberBanned Vendor.Signal<{ guildId: string, user: Objects.DiscordUser }>
			@within Objects.EventManager
		]=]
		onGuildMemberBanned = Signal.new(),

		--[=[
			@prop onGuildMemberUnbanned Vendor.Signal<{ guildId: string, user: Objects.DiscordUser }>
			@within Objects.EventManager
		]=]
		onGuildMemberUnbanned = Signal.new(),

		--[=[
			@prop onGuildMemberJoined Vendor.Signal<Objects.DiscordGuildMember & { guildId: string }>
			@within Objects.EventManager
		]=]
		onGuildMemberJoined = Signal.new(),

		--[=[
			@prop onGuildMemberLeft Vendor.Signal<{ guildId: string, user: Objects.DiscordUser }>
			@within Objects.EventManager
		]=]
		onGuildMemberLeft = Signal.new(),

		--[=[
			@prop onGuildMemberUpdated Vendor.Signal<{ ... }>
			@within Objects.EventManager
		]=]
		onGuildMemberUpdated = Signal.new(),

		--[=[
			@prop onInteraction Vendor.Signal<Objects.DiscordInteraction>
			@within Objects.EventManager

			Fires when an interaction occurs.
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
