--[=[
	@class Classes.Channels.ChannelMention
	@__index Prototype

	Implementation of the Discord ChannelMention class in Luau

	https://discord.com/developers/docs/resources/message#channel-mention-object
]=]

--[=[
	@prop type Classes.ChannelType
	@within Classes.Channels.ChannelMention
	
	The type of channel that was mentioned. This represents the channel's type as defined in Discord's API.
]=]

--[=[
	@prop id string
	@within Classes.Channels.ChannelMention
	
	The unique identifier of the mentioned channel. This is a Discord snowflake ID.
]=]

--[=[
	@prop name string
	@within Classes.Channels.ChannelMention
	
	The name of the mentioned channel. This is the channel's display name without the # prefix.
]=]

--[=[
	@prop guildId string
	@within Classes.Channels.ChannelMention
	
	The ID of the guild (server) that the mentioned channel belongs to. This is a Discord snowflake ID.
]=]

local apiTypes = require("../../luau_packages/api_types")

local ChannelMention = {}

ChannelMention.Interface = {}
ChannelMention.Prototype = {}

--[=[
	@within Classes.Channels.ChannelMention
	@private

	Responsible for syncing data to this channel mention object. This is typically called by the API when this object is
	created or updated.
]=]
function ChannelMention.Prototype.sync(self: ChannelMention, mentionData: apiTypes.ChannelMentionObject)
	self.type = apiTypes.channel.ChannelTypes[mentionData.type]

	self.id = mentionData.id

	self.name = mentionData.name

	self.guildId = mentionData.guild_id
end

--[=[
	@within Classes.Channels.ChannelMention
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
