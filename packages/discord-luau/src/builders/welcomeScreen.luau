local construct = require("@util/construct")

local Resolvable = require("@network/resolvable")

local ResolvableType = require("@enums/resolvableType")

--[=[
	@class Builders.WelcomeScreenBuilder

	WelcomeScreenBuilder allows you to build welcome screens for discord guilds.

	Usage:
	```lua
	local DiscordLuau = require("../Submodules/DiscordLuau")

	local WelcomeScreenBuilder = DiscordLuau.WelcomeScreenBuilder.new()
		:addChannel("1048686561685946489", "Super cool discord channel")
		:setDescription("Yeah, a super awesome dsicord channel!")
	```
]=]
local WelcomeScreenBuilder = {}

WelcomeScreenBuilder.Interface = {}
WelcomeScreenBuilder.Prototype = {}

WelcomeScreenBuilder.Prototype.type = "WelcomeScreenBuilder"

--[=[
	Adds a channel object to the guilds Welcome Screen
	
	@method addChannel
	@param channelId string
	@param description string
	@param emojiId string
	@param emojiName string
	@within Builders.WelcomeScreenBuilder
	@return Builders.WelcomeScreenBuilder
]=]
function WelcomeScreenBuilder.Prototype.addChannel(
	self: WelcomeScreenBuilder,
	channelId: string,
	description: string,
	emojiId: string?,
	emojiName: string?
)
	table.insert(self.welcomeChannels, {
		channelId = channelId,
		description = description,

		emojiId = emojiId,
		emojiName = emojiName,
	})

	return self
end

--[=[
	Adds a channel object to the guilds Welcome Screen
	
	@method setDescription
	@param description string
	@within Builders.WelcomeScreenBuilder
	@return Builders.WelcomeScreenBuilder
]=]
function WelcomeScreenBuilder.Prototype.setDescription(self: WelcomeScreenBuilder, description: string)
	self.description = description

	return self
end

--[=[
	Converts the message to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.WelcomeScreenBuilder
	@return Network.Resolvable
]=]
function WelcomeScreenBuilder.Prototype.toPayloadObject(self: WelcomeScreenBuilder): Resolvable.Resolvable
	local welcomeChannels = {}

	for index, welcomeChannel in self.welcomeChannels do
		welcomeChannels[index] = {
			channel_id = welcomeChannel.channelId,
			description = welcomeChannel.description,

			emoji_id = welcomeChannel.emojiId,
			emoji_name = welcomeChannel.emojiName,
		}
	end

	return Resolvable.new(ResolvableType.JSON, {
		description = self.description,

		welcome_channels = #welcomeChannels > 0 and welcomeChannels or nil,
	})
end

--[=[
	Creates a new instance of WelcomeScreenBuilder.
	
	@function new
	@within Builders.WelcomeScreenBuilder
	@return Builders.
]=]
function WelcomeScreenBuilder.Interface.new()
	return (construct({
		welcomeChannels = {},
	}, WelcomeScreenBuilder.Prototype) :: unknown) :: WelcomeScreenBuilder
end

export type WelcomeScreenBuilder = typeof(WelcomeScreenBuilder.Prototype) & {
	description: string?,

	welcomeChannels: {
		{
			channelId: string,
			description: string,

			emojiId: string?,
			emojiName: string?,
		}
	},
}

return WelcomeScreenBuilder.Interface
