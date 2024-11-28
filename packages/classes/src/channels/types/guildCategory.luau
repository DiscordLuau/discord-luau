--[[
	Implementation of the Discord GuildCategory class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")

local GuildCategory = {}

GuildCategory.Interface = {}
GuildCategory.Prototype = {}
GuildCategory.Behaviours = {
	channelBehaviour,
	guildBehaviour,
}

function GuildCategory.Prototype.sync(self: GuildCategory, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildCategory.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

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
