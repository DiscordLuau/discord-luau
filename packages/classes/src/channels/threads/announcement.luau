--[=[
	@class Classes.Channels.AnnouncementThread
	@__index Prototype
	@tag inherit:Classes.Channels.Channel
	@tag inherit:Classes.Channels.GuildBehaviour
	@tag inherit:Classes.Channels.ThreadBehaviour
	@tag inherit:Classes.Channels.TextBehaviour

	Implementation of the Discord Announcement class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

--[=[
	@prop state Classes.State
	@within Classes.Channels.AnnouncementThread
]=]

local apiTypes = require("../../../luau_packages/api_types")
local state = require("../../../luau_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local textBehaviour = require("../behaviour/text")
local threadBehaviour = require("../behaviour/thread")

local Announcement = {}

Announcement.Interface = {}
Announcement.Prototype = {}
Announcement.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	threadBehaviour,
	textBehaviour,
}

--[=[
	@within Classes.Channels.AnnouncementThread
	@private

	Responsible for syncing data to this announcement object. This is typically called by the API when this object is
	created or updated.
]=]
function Announcement.Prototype.sync(self: Announcement, channelData: apiTypes.ChannelObject)
	for _, behaviour in Announcement.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.Channels.AnnouncementThread
	@private

	Responsible for constructing this class.
]=]
function Announcement.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): Announcement
	local self = setmetatable(
		{
			state = state,
		} :: Announcement,
		{ __index = Announcement.Prototype }
	)

	self:sync(channelData)

	return self
end

export type Announcement =
	typeof(Announcement.Prototype)
	& {
		state: state.State,
	}
	& channelBehaviour.ChannelBehaviour
	& textBehaviour.TextBehaviour
	& guildBehaviour.GuildBehaviour
	& threadBehaviour.ThreadBehaviour

return Announcement.Interface
