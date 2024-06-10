local Construct = require("@Utils/Construct")

local Resolvable = require("@Network/Resolvable")

local ResolvableType = require("@Enums/ResolvableType")

--[=[
	@class Builders.OnboardingPromptOptionBuilder

	OnboardingPromptOptionBuilder allows you to build onboarding for discord guilds.

	Usage:
	```lua
	local DiscordLuau = require("../Submodules/DiscordLuau")

	local OnboardingPromptOptionBuilder = DiscordLuau.OnboardingPromptOptionBuilder.new()
		:setTitle("option-name")
		:setDescription("Option Description!")
	```
]=]
local OnboardingPromptOptionBuilder = {}

OnboardingPromptOptionBuilder.Interface = {}
OnboardingPromptOptionBuilder.Prototype = {}

OnboardingPromptOptionBuilder.Prototype.type = "OnboardingPromptOptionBuilder"

--[=[
	Sets the title of the Prompt Option builder
	
	@method setTitle
	@param title string
	@within Builders.OnboardingPromptOptionBuilder
	@return Builders.OnboardingPromptOptionBuilder
]=]
function OnboardingPromptOptionBuilder.Prototype.setTitle(self: OnboardingPromptOptionBuilder, title: string)
	self.title = title

	return self
end

--[=[
	Sets the description of the Prompt Option builder
	
	@method setDescription
	@param description string
	@within Builders.OnboardingPromptOptionBuilder
	@return Builders.OnboardingPromptOptionBuilder
]=]
function OnboardingPromptOptionBuilder.Prototype.setDescription(
	self: OnboardingPromptOptionBuilder,
	description: string
)
	self.description = description

	return self
end

--[=[
	Add a channel id to the prompt option builder
	
	@method addChannelId
	@param channelId string
	@within Builders.OnboardingPromptOptionBuilder
	@return Builders.OnboardingPromptOptionBuilder
]=]
function OnboardingPromptOptionBuilder.Prototype.addChannelId(self: OnboardingPromptOptionBuilder, channelId: string)
	table.insert(self.channelIds, channelId)

	return self
end

--[=[
	Add a role id to the prompt option builder
	
	@method addRoleId
	@param roleId string
	@within Builders.OnboardingPromptOptionBuilder
	@return Builders.OnboardingPromptOptionBuilder
]=]
function OnboardingPromptOptionBuilder.Prototype.addRoleId(self: OnboardingPromptOptionBuilder, roleId: string)
	table.insert(self.roleIds, roleId)

	return self
end

--[=[
	Sets the emoji of the Onboarding Prompt Option Builder
	
	@method setEmoji
	@param emojiId string
	@param emojiName string
	@param emojiAnimated boolean?
	@within Builders.OnboardingPromptOptionBuilder
	@return Builders.OnboardingPromptOptionBuilder
]=]
function OnboardingPromptOptionBuilder.Prototype.setEmoji(
	self: OnboardingPromptOptionBuilder,
	emojiId: string,
	emojiName: string,
	emojiAnimated: boolean?
)
	self.emojiId = emojiId
	self.emojiName = emojiName
	self.emojiAnimated = emojiAnimated or false

	return self
end

--[=[
	Converts the message to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.OnboardingBuilder
	@return Network.Resolvable
]=]
function OnboardingPromptOptionBuilder.Prototype.toPayloadObject(
	self: OnboardingPromptOptionBuilder
): Resolvable.Resolvable
	return Resolvable.new(ResolvableType.JSON, {
		title = self.title,
		description = self.description,
		emoji_id = self.emojiId,
		emoji_name = self.emojiName,
		emoji_animated = self.emojiAnimated,

		channels_ids = #self.channelIds > 0 and self.channelIds or nil,
		role_ids = #self.roleIds > 0 and self.roleIds or nil,
	})
end

--[=[
	
	Creates a new instance of OnboardingPromptOptionBuilder with the specified intents.
	
	@function new
	@param intentList { string } -- A list of intents to include.
	@within Builders.OnboardingPromptOptionBuilder
	@return Builders.OnboardingPromptOptionBuilder -- A new instance of OnboardingPromptOptionBuilder.
]=]
function OnboardingPromptOptionBuilder.Interface.new()
	return (
		Construct({
			channelIds = {},
			roleIds = {},
		}, OnboardingPromptOptionBuilder.Prototype) :: unknown
	) :: OnboardingPromptOptionBuilder
end

export type OnboardingPromptOptionBuilder = typeof(OnboardingPromptOptionBuilder.Prototype) & {
	channelIds: { string },
	roleIds: { string },
	emojiId: string?,
	emojiName: string?,
	emojiAnimated: boolean?,
	title: string,
	description: string?,
}

return OnboardingPromptOptionBuilder.Interface
