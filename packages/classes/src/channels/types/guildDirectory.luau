--[[
	Implementation of the Discord GuildDirectory class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

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

function GuildDirectory.Prototype.sync(self: GuildDirectory, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildDirectory.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

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
