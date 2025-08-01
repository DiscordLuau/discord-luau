--[=[
	@class Classes.ChannelMention
	@__index Prototype

	Implementation of the Discord ChannelMention class in Luau

	https://discord.com/developers/docs/resources/message#channel-mention-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local ChannelMention = {}

ChannelMention.Interface = {}
ChannelMention.Prototype = {}

--[=[
	@within Classes.ChannelMention
	@private

	Responsible for syncing data to this channel mention object. This is typically called by the API when this object is
	created or updated.
]=]
function ChannelMention.Prototype.sync(self: ChannelMention, mentionData: apiTypes.ChannelMentionObject)
	--[=[
		@prop type Classes.ChannelType
		@within Classes.ChannelMention
		
		The type of channel that was mentioned. This represents the channel's type as defined in Discord's API.
	]=]
	self.type = apiTypes.channel.ChannelTypes[mentionData.type]

	--[=[
		@prop id string
		@within Classes.ChannelMention
		
		The unique identifier of the mentioned channel. This is a Discord snowflake ID.
	]=]
	self.id = mentionData.id

	--[=[
		@prop name string
		@within Classes.ChannelMention
		
		The name of the mentioned channel. This is the channel's display name without the # prefix.
	]=]
	self.name = mentionData.name

	--[=[
		@prop guildId string
		@within Classes.ChannelMention
		
		The ID of the guild (server) that the mentioned channel belongs to. This is a Discord snowflake ID.
	]=]
	self.guildId = mentionData.guild_id
end

--[=[
	@within Classes.ChannelMention
	@private

	Responsible for constructing this class.
]=]
function ChannelMention.Interface.new(mentionData: apiTypes.ChannelMentionObject): ChannelMention
	local self = setmetatable({} :: ChannelMention, { __index = ChannelMention.Prototype })

	self:sync(mentionData)

	return self
end

export type ChannelMention = typeof(ChannelMention.Prototype) & {
	id: apiTypes.Snowflake,
	guildId: apiTypes.Snowflake,
	type: apiTypes.ChannelType,
	name: string,
}

return ChannelMention.Interface
