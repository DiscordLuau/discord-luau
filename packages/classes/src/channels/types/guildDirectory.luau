--[=[
	@class Classes.GuildDirectory
	@__index Prototype

	Implementation of the Discord GuildDirectory class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

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
	@within Classes.GuildDirectory
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
	@within Classes.GuildDirectory
	@private

	Responsible for constructing this class.
]=]
function GuildDirectory.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GuildDirectory
	local self = setmetatable(
		{
			--[=[
				@prop state Classes.State
				@within Classes.GuildDirectory
			]=]
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
