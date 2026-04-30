--[=[
	@class Classes.Channels.GuildDirectory
	@__index Prototype
	@tag inherit:Classes.Channels.Channel
	@tag inherit:Classes.Channels.GuildBehaviour

	Implementation of the Discord GuildDirectory class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

--[=[
	@prop state Classes.State
	@within Classes.Channels.GuildDirectory
]=]

local apiTypes = require("../../../luau_packages/api_types")
local state = require("../../../luau_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")

local GuildDirectory = {}

GuildDirectory.Interface = {}
GuildDirectory.Prototype = {}
GuildDirectory.Behaviours = {
	channelBehaviour,
	guildBehaviour,
}

--[=[
	@within Classes.Channels.GuildDirectory
	@private

	Responsible for syncing data to this guild directory object. This is typically called by the API when this object is
	created or updated.
]=]
function GuildDirectory.Prototype.sync(self: GuildDirectory, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildDirectory.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.Channels.GuildDirectory
	@private

	Responsible for constructing this class.
]=]
function GuildDirectory.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GuildDirectory
	local self = setmetatable(
		{
			state = state,
		} :: GuildDirectory,
		{ __index = GuildDirectory.Prototype }
	)

	self:sync(channelData)

	return self
end

export type GuildDirectory = typeof(GuildDirectory.Prototype) & {
	state: state.State,
} & channelBehaviour.ChannelBehaviour & guildBehaviour.GuildBehaviour

return GuildDirectory.Interface
