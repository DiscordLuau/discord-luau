--[=[
	@class Classes.Channels.GuildCategory
	@__index Prototype
	@tag inherit:Classes.Channels.Channel
	@tag inherit:Classes.Channels.GuildBehaviour

	Implementation of the Discord GuildCategory class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

--[=[
	@prop state Classes.State
	@within Classes.Channels.GuildCategory
]=]

local apiTypes = require("../../../luau_packages/api_types")
local state = require("../../../luau_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")

local GuildCategory = {}

GuildCategory.Interface = {}
GuildCategory.Prototype = {}
GuildCategory.Behaviours = {
	channelBehaviour,
	guildBehaviour,
}

--[=[
	@within Classes.Channels.GuildCategory
	@private

	Responsible for syncing data to this channel object. This is typically called by the API when this object is
	created or updated.
]=]
function GuildCategory.Prototype.sync(self: GuildCategory, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildCategory.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.Channels.GuildCategory
	@private

	Responsible for constructing this class.
]=]
function GuildCategory.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GuildCategory
	local self = setmetatable(
		{
			state = state,
		} :: GuildCategory,
		{ __index = GuildCategory.Prototype }
	)

	self:sync(channelData)

	return self
end

export type GuildCategory = typeof(GuildCategory.Prototype) & {
	state: state.State,
} & channelBehaviour.ChannelBehaviour & guildBehaviour.GuildBehaviour

return GuildCategory.Interface
