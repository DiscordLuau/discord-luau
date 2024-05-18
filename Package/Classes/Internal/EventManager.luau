local Task = require("../../Std/Task")

local Construct = require("../../Utils/Construct")

local DiscordEvents = require("../../Enums/DiscordEvents")

local DiscordMessage = require("DiscordMessage")
local DiscordChannel = require("DiscordChannel")

local DiscordUser = require("DiscordUser")
local DiscordGuild = require("DiscordGuild")
local DiscordGuildMember = require("DiscordGuildMember")

local DiscordInteraction = require("DiscordInteraction")

local Signal = require("../../Vendor/Signal")

--[=[
	@class Internal.EventManager

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local EventManager = {}

EventManager.Prototype = {}
EventManager.Interface = {}

EventManager.Prototype.type = "EventManager"

function EventManager.Interface.new(discordClient): EventManager
	local self = Construct({
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

	discordClient.onEvent:connect(function(eventName: DiscordEvents.DiscordEvent, ...)
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
		communicationDisabledUntil: string?
	}>,

	onInteraction: Signal.Signal<DiscordInteraction.DiscordInteraction>,
}

return EventManager.Interface