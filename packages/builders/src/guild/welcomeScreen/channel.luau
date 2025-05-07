--[=[
	@class Builders.WelcomeScreenChannel
	@__index Prototype

	Implementation of discords WelcomeScreenChannel object as a Luau builder.	

	https://discord.com/developers/docs/resources/guild#welcome-screen-object-welcome-screen-channel-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local WelcomeScreenChannel = {}

WelcomeScreenChannel.Prototype = {}
WelcomeScreenChannel.Interface = {}

--[=[
	@within Builders.WelcomeScreenChannel

	Set the channel id for this welcome screen channel
]=]
function WelcomeScreenChannel.Prototype.setChannelId(
	self: WelcomeScreenChannel,
	channelId: apiTypes.Snowflake
): WelcomeScreenChannel
	self.channelId = channelId

	return self
end

--[=[
	@within Builders.WelcomeScreenChannel

	Set the description for this welcome screen channel
]=]
function WelcomeScreenChannel.Prototype.setDescription(
	self: WelcomeScreenChannel,
	description: string
): WelcomeScreenChannel
	-- todo: validate size of description

	self.description = description

	return self
end

--[=[
	@within Builders.WelcomeScreenChannel

	Set the emoji id for this welcome screen channel
]=]
function WelcomeScreenChannel.Prototype.setEmojiId(
	self: WelcomeScreenChannel,
	emojiId: apiTypes.Snowflake
): WelcomeScreenChannel
	self.emojiId = emojiId

	return self
end

--[=[
	@within Builders.WelcomeScreenChannel

	Set the emoji name for this welcome screen channel
]=]
function WelcomeScreenChannel.Prototype.setEmojiName(
	self: WelcomeScreenChannel,
	emojiName: string
): WelcomeScreenChannel
	self.emojiName = emojiName

	return self
end

--[=[
	@within Builders.WelcomeScreenChannel

	Responsible for building the WelcomeScreenChannelObject JSON that can be parsed by the Discord API.
]=]
function WelcomeScreenChannel.Prototype.build(self: WelcomeScreenChannel): JSON
	return {
		channel_id = self.channelId,
		description = self.description,
		emoji_id = self.emojiId,
		emoji_name = self.emojiName,
	}
end

--[=[
	@within Builders.WelcomeScreenChannel

	Responsible for creating a new WelcomeScreenChannel.
]=]
function WelcomeScreenChannel.Interface.new(resource: {
	channelId: apiTypes.Snowflake?,
	description: string?,
	emojiId: apiTypes.Snowflake?,
	emojiName: string?,
}?): WelcomeScreenChannel
	local self = setmetatable(
		{
			--[=[
				@prop channelId string?
				@within Builders.WelcomeScreenChannel
				The id of the channel shown in the welcome screen.
			]=]
			channelId = nil,

			--[=[
				@prop description string
				@within Builders.WelcomeScreenChannel
				The description shown for the channel in the welcome screen.
			]=]
			description = nil,

			--[=[
				@prop emojiId string?
				@within Builders.WelcomeScreenChannel
				The id of the emoji shown in the welcome screen channel.
			]=]
			emojiId = nil,

			--[=[
				@prop emojiName string?
				@within Builders.WelcomeScreenChannel
				The name of the emoji shown in the welcome screen channel.
			]=]
			emojiName = nil,
		} :: WelcomeScreenChannel,
		{
			__index = WelcomeScreenChannel.Prototype,
		}
	)

	if resource then
		if resource.channelId then
			self:setChannelId(resource.channelId)
		end

		if resource.description then
			self:setDescription(resource.description)
		end

		if resource.emojiId then
			self:setEmojiId(resource.emojiId)
		end

		if resource.emojiName then
			self:setEmojiName(resource.emojiName)
		end
	end

	return self
end

export type WelcomeScreenChannel = typeof(WelcomeScreenChannel.Prototype) & {
	channelId: apiTypes.Snowflake?,
	description: string,
	emojiId: apiTypes.Snowflake?,
	emojiName: string?,
}

export type JSON = typeof(WelcomeScreenChannel.Prototype.build(nil :: any))

return WelcomeScreenChannel.Interface
