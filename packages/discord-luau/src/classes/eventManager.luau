local Signal = require("@dep/signal")

local construct = require("@util/construct")

local DiscordMessage = require("@classes/message")
local DiscordChannel = require("@classes/channel")

local DiscordUser = require("@classes/user")
local DiscordGuild = require("@classes/guild")
local DiscordGuildMember = require("@classes/guild/member")

local DiscordInteraction = require("@classes/interaction")

local DiscordEvents = require("@enums/discordEvents")

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
	@param discordClient any
	@within Objects.EventManager
	@return EventManager
]=]
function EventManager.Interface.new(discordClient): EventManager
	--[=[
		@prop onReady Vendor.Signal<>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onMessage Vendor.Signal<Objects.DiscordMessage>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onMessageChanged Vendor.Signal<Objects.DiscordMessage>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onMessageDeleted Vendor.Signal<Objects.DiscordMessage>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onMessageBulkDeleted Vendor.Signal<{ channelId: string, guildId: string, ids: { string } }>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onChannelCreate Vendor.Signal<Objects.DiscordChannel>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onChannelUpdate Vendor.Signal<Objects.DiscordChannel>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onChannelDelete Vendor.Signal<Objects.DiscordChannel>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onUserUpdated Vendor.Signal<Objects.DiscordUser>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onChannelPinsUpdate Vendor.Signal<{ guildId: string, channelId: string, lastPinTimestamp: string }>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onGuildCreate Vendor.Signal<Objects.DiscordGuild>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onGuildUpdate Vendor.Signal<Objects.DiscordGuild>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onGuildDelete Vendor.Signal<Objects.DiscordGuild>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onGuildMemberBanned Vendor.Signal<{ guildId: string, user: Objects.DiscordUser }>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onGuildMemberUnbanned Vendor.Signal<{ guildId: string, user: Objects.DiscordUser }>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onGuildMemberJoined Vendor.Signal<Objects.DiscordGuildMember & { guildId: string }>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onGuildMemberLeft Vendor.Signal<{ guildId: string, user: Objects.DiscordUser }>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onGuildMemberUpdated Vendor.Signal<{ ... }>
		@within Objects.EventManager
	]=]

	--[=[
		@prop onInteraction Vendor.Signal<Objects.DiscordInteraction>
		@within Objects.EventManager

		Fires when an interaction occurs.
	]=]

	local self = construct({
		onReady = Signal.new(),
		onMessage = Signal.new(),
		onMessageChanged = Signal.new(),
		onMessageDeleted = Signal.new(),
		onMessageBulkDeleted = Signal.new(),
		onChannelCreate = Signal.new(),
		onChannelUpdate = Signal.new(),
		onChannelDelete = Signal.new(),
		onUserUpdated = Signal.new(),
		onChannelPinsUpdate = Signal.new(),
		onGuildCreate = Signal.new(),
		onGuildUpdate = Signal.new(),
		onGuildDelete = Signal.new(),
		onGuildMemberBanned = Signal.new(),
		onGuildMemberUnbanned = Signal.new(),
		onGuildMemberJoined = Signal.new(),
		onGuildMemberLeft = Signal.new(),
		onGuildMemberUpdated = Signal.new(),
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
