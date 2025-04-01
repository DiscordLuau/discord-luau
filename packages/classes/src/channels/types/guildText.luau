--[=[
	@class Classes.GuildText
	@__index Prototype

	Implementation of the Discord GuildText class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local textBehaviour = require("../behaviour/text")

local GuildText = {}

GuildText.Interface = {}
GuildText.Prototype = {}
GuildText.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	textBehaviour,
}

--[=[
	@within Classes.GuildText
	@private

	Responsible for syncing data to this guild text channel object. This is typically called by the API when this object is
	created or updated.
]=]
function GuildText.Prototype.sync(self: GuildText, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildText.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.GuildText
	@private

	Responsible for constructing this class.
]=]
function GuildText.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): GuildText
	--[=[
		@prop state state.State
		@within Classes.GuildText
	]=]
	local self = setmetatable(
		{
			state = state,
		} :: GuildText,
		{ __index = GuildText.Prototype }
	)

	self:sync(channelData)

	return self
end

export type GuildText = typeof(GuildText.Prototype) & {
	state: state.State,
} & channelBehaviour.ChannelBehaviour & textBehaviour.TextBehaviour & guildBehaviour.GuildBehaviour

return GuildText.Interface
