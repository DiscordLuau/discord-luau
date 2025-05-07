--[=[
	@class Classes.GuildAnnouncement
	@__index Prototype

	Implementation of the Discord GuildAnnouncement class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")
local future = require("../../../luau_packages/future")
local rest = require("../../../lune_packages/rest")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local textBehaviour = require("../behaviour/text")

local GuildAnnouncement = {}

GuildAnnouncement.Interface = {}
GuildAnnouncement.Prototype = {}
GuildAnnouncement.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	textBehaviour,
}

--[=[
	@within Classes.GuildAnnouncement

	Crosspost a message in an Announcement Channel to following channels. This endpoint requires the SEND_MESSAGES
	permission, if the current user sent the message, or additionally the MANAGE_MESSAGES permission, for all
	other messages, to be present for the current user.
]=]
function GuildAnnouncement.Prototype.crosspostAsync(self: GuildAnnouncement, messageId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.message.crosspostMessageAsync(request, self.id, messageId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().id :: any
	end) :: future.FutureLike<string, string>
end

--[=[
	@within Classes.GuildAnnouncement

	Follow an Announcement Channel to send messages to a target channel. Requires the MANAGE_WEBHOOKS permission
	in the target channel. 
]=]
function GuildAnnouncement.Prototype.followAsync(self: GuildAnnouncement, targetChannelId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.channel
			.followAnnouncementChannelAsync(request, self.id, {
				webhook_channel_id = targetChannelId,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().webhook_id
	end) :: future.FutureLike<string, string>
end

--[=[
	@within Classes.GuildAnnouncement
	@private

	Responsible for syncing data to this announcement channel object. This is typically called by the API when this object is
	created or updated.
]=]
function GuildAnnouncement.Prototype.sync(self: GuildAnnouncement, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildAnnouncement.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.GuildAnnouncement
	@private

	Responsible for constructing this class.
]=]
function GuildAnnouncement.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GuildAnnouncement
	--[=[
		@prop state state.State
		@within Classes.GuildAnnouncement
	]=]
	local self = setmetatable(
		{
			state = state,
		} :: GuildAnnouncement,
		{ __index = GuildAnnouncement.Prototype }
	)

	self:sync(channelData)

	return self
end

export type GuildAnnouncement = typeof(GuildAnnouncement.Prototype) & {
	state: state.State,
} & channelBehaviour.ChannelBehaviour & textBehaviour.TextBehaviour & guildBehaviour.GuildBehaviour

return GuildAnnouncement.Interface
