--[=[
	@class Classes.WelcomeScreenChannel
	@__index Prototype

	Implementation of the Discord WelcomeScreenChannel class in Luau

	https://discord.com/developers/docs/resources/guild#welcome-screen-object-welcome-screen-channel-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local WelcomeScreenChannel = {}

WelcomeScreenChannel.Interface = {}
WelcomeScreenChannel.Prototype = {}

--[=[
	@within Classes.WelcomeScreenChannel
	@private

	Responsible for syncing data to this welcome screen channel object. This is typically called by the API when this object is
	created or updated.
]=]
function WelcomeScreenChannel.Prototype.sync(
	self: WelcomeScreenChannel,
	welcomeScreenData: apiTypes.WelcomeScreenChannelObject
)
	--[=[
		@prop channelId string
		@within Classes.WelcomeScreenChannel

		The id of the channel that is shown in the welcome screen
	]=]
	self.channelId = welcomeScreenData.channel_id

	--[=[
		@prop description string
		@within Classes.WelcomeScreenChannel

		The description shown for the channel in the welcome screen
	]=]
	self.description = welcomeScreenData.description

	--[=[
		@prop emojiId string
		@within Classes.WelcomeScreenChannel

		The id of the emoji that is shown alongside the channel
	]=]
	self.emojiId = welcomeScreenData.emoji_id

	--[=[
		@prop emojiName string
		@within Classes.WelcomeScreenChannel

		The name of the emoji that is shown alongside the channel
	]=]
	self.emojiName = welcomeScreenData.emoji_name
end

--[=[
	@within Classes.WelcomeScreenChannel
	@private

	Responsible for constructing this class.
]=]
function WelcomeScreenChannel.Interface.new(roleTagData: apiTypes.WelcomeScreenChannelObject): WelcomeScreenChannel
	local self = setmetatable({} :: WelcomeScreenChannel, { __index = WelcomeScreenChannel.Prototype })

	self:sync(roleTagData)

	return self
end

export type WelcomeScreenChannel = typeof(WelcomeScreenChannel.Prototype) & {
	channelId: apiTypes.Snowflake?,
	description: string?,
	emojiId: apiTypes.Snowflake?,
	emojiName: string?,
}

return WelcomeScreenChannel.Interface
