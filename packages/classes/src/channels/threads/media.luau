--[=[
	@class Classes.Media
	@__index Prototype

	Implementation of the Discord Media class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local channelBehaviour = require("../behaviour/channel")
local guildBehaviour = require("../behaviour/guild")
local textBehaviour = require("../behaviour/text")
local threadBehaviour = require("../behaviour/thread")
local mediaBehaviour = require("../behaviour/media")

local Media = {}

Media.Interface = {}
Media.Prototype = {}
Media.Behaviours = {
	channelBehaviour,
	guildBehaviour,
	threadBehaviour,
	mediaBehaviour,
	textBehaviour,
}

--[=[
	@within Classes.Media
	@private

	Responsible for syncing data to this media object. This is typically called by the API when this object is
	created or updated.
]=]
function Media.Prototype.sync(self: Media, channelData: apiTypes.ChannelObject)
	for _, behaviour in Media.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

--[=[
	@within Classes.Media
	@private

	Responsible for constructing this class.
]=]
function Media.Interface.new(state: state.State, channelData: apiTypes.ChannelObject): Media
	local self = setmetatable(
		{
			--[=[
				@prop state Classes.State
				@within Classes.Media
			]=]
			state = state,
		} :: Media,
		{ __index = Media.Prototype }
	)

	self:sync(channelData)

	return self
end

export type Media =
	typeof(Media.Prototype)
	& {
		state: state.State,
	}
	& channelBehaviour.ChannelBehaviour
	& textBehaviour.TextBehaviour
	& guildBehaviour.GuildBehaviour
	& threadBehaviour.ThreadBehaviour
	& mediaBehaviour.MediaBehaviour

return Media.Interface
