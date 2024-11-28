--[[
	Implementation of the Discord WelcomeScreenChannel class in Luau

	https://discord.com/developers/docs/resources/guild#welcome-screen-object-welcome-screen-channel-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local WelcomeScreenChannel = {}

WelcomeScreenChannel.Interface = {}
WelcomeScreenChannel.Prototype = {}

function WelcomeScreenChannel.Prototype.sync(
	self: WelcomeScreenChannel,
	welcomeScreenData: apiTypes.WelcomeScreenChannelObject
)
	self.channelId = welcomeScreenData.channel_id
	self.description = welcomeScreenData.description
	self.emojiId = welcomeScreenData.emoji_id
	self.emojiName = welcomeScreenData.emoji_name
end

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
