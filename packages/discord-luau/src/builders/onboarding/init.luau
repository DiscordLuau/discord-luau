local construct = require("@util/construct")
local Enumerate = require("@util/enumerate")

local Resolvable = require("@network/resolvable")

local OnboardingPromptBuilder = require("@builders/onboarding/prompt")

local ResolvableType = require("@enums/resolvableType")

--[=[
	@class Builders.OnboardingBuilder

	OnboardingBuilder allows you to build onboarding for discord guilds.

	Usage:
	```lua
	local DiscordLuau = require("../Submodules/DiscordLuau")

	local OnboardingBuilder = DiscordLuau.OnboardingBuilder.new()
		:setMode(DiscordLuau.OnboardingBuilder.Mode.Default)
		:setEnabled(true)
		:addChannelId("1048686561685946489")
	```
]=]
local OnboardingBuilder = {}

OnboardingBuilder.Interface = {}
OnboardingBuilder.Prototype = {}

OnboardingBuilder.Prototype.type = "OnboardingBuilder"

--[=[
	@prop Mode table
	@within Builders.OnboardingBuilder

	An enumeration of onboarding modes

	- Default: 0
	- Advanced: 1
]=]
OnboardingBuilder.Interface.Mode = Enumerate.new({
	Default = 0,
	Advanced = 1,
})

--[=[
	Sets the mode of the Guild onbaording object
	
	@method setMode
	@param mode number
	@within Builders.OnboardingBuilder
	@return Builders.OnboardingBuilder
]=]
function OnboardingBuilder.Prototype.setMode(self: OnboardingBuilder, mode: number)
	OnboardingBuilder.Interface.Mode:Assert(mode)

	self.mode = mode

	return self
end

--[=[
	Sets if the guild onboarding is enabled or not
	
	@method setEnabled
	@param isEnabled boolean
	@within Builders.OnboardingBuilder
	@return Builders.OnboardingBuilder
]=]
function OnboardingBuilder.Prototype.setEnabled(self: OnboardingBuilder, isEnabled: boolean)
	self.enabled = isEnabled

	return self
end

--[=[
	Channel IDs that members get opted into automatically
	
	@method addChannelId
	@param channelId string
	@within Builders.OnboardingBuilder
	@return Builders.OnboardingBuilder
]=]
function OnboardingBuilder.Prototype.addChannelId(self: OnboardingBuilder, channelId: string)
	table.insert(self.defaultChannelIds, channelId)

	return self
end

--[=[
	Channel IDs that members get opted into automatically
	
	@method addOnboardingPrompt
	@param prompt Objects.OnboardingPromptBuilder
	@within Builders.OnboardingBuilder
	@return Builders.OnboardingBuilder
]=]
function OnboardingBuilder.Prototype.addOnboardingPrompt(
	self: OnboardingBuilder,
	prompt: OnboardingPromptBuilder.OnboardingPromptBuilder
)
	table.insert(self.prompts, prompt)

	return self
end

--[=[
	Converts the message to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.OnboardingBuilder
	@return Network.Resolvable
]=]
function OnboardingBuilder.Prototype.toPayloadObject(self: OnboardingBuilder): Resolvable.Resolvable
	local prompts = {}

	for index, prompt in self.prompts do
		prompts[index] = prompt:toPayloadObject():resolve()
	end

	return Resolvable.new(ResolvableType.JSON, {
		enabled = self.enabled,
		mode = self.mode,

		prompts = #prompts > 0 and prompts or nil,
		default_channel_ids = #self.defaultChannelIds > 0 and self.defaultChannelIds or nil,
	})
end

--[=[
	Creates a new instance of OnboardingBuilder.
	
	@function new
	@within Builders.OnboardingBuilder
	@return Builders.OnboardingBuilder
]=]
function OnboardingBuilder.Interface.new()
	return (
		construct({
			prompts = {},
			defaultChannelIds = {},
		}, OnboardingBuilder.Prototype) :: unknown
	) :: OnboardingBuilder
end

export type OnboardingBuilder = typeof(OnboardingBuilder.Prototype) & {
	enabled: boolean,
	mode: number,

	defaultChannelIds: { string },
	prompts: { OnboardingPromptBuilder.OnboardingPromptBuilder },
}

return OnboardingBuilder.Interface
