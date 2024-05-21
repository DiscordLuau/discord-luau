local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class ApplicationCommandOptionBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local ApplicationCommandOptionBuilder = {}

ApplicationCommandOptionBuilder.Interface = {}
ApplicationCommandOptionBuilder.Prototype = {}

ApplicationCommandOptionBuilder.Prototype.type = "ApplicationCommandOptionBuilder"

--[=[
	@prop Type { ... }
	@within ApplicationCommandOptionBuilder
]=]
ApplicationCommandOptionBuilder.Interface.Type = Enumerate.new({
	SubCommand = 1,
	SubCommandGroup = 2,
	String = 3,
	Integer = 4,
	Boolean = 5,
	User = 6,
	Channel = 7,
	Role = 8,
	Mentionable = 9,
	Number = 10,
	Attachment = 11
})

--[=[
	@prop ChannelType { ... }
	@within ApplicationCommandOptionBuilder
]=]
ApplicationCommandOptionBuilder.Interface.ChannelType = Enumerate.new({
	GuildText = 0,
	DirectMessage = 1,
	GuildVoice = 2,
	GroupDirectMessage = 3,
	GuildCategory = 4,
	GuildAnnouncement = 5,
	AnnouncementThread = 10,
	PublicThread = 11,
	PrivateThread = 12,
	GuildStageVoice = 13,
	GuildDirectory = 14,
	GuildForum = 15,
})

--[=[
	@method setType
	@within ApplicationCommandOptionBuilder

	@param optionType string

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setType(self: ApplicationCommandOptionBuilder, optionType: number)
	assert(ApplicationCommandOptionBuilder.Interface.Type:Is(optionType), `Expected 'optionType' to of enum 'optionType'`)

	self.optionType = optionType

	return self
end

--[=[
	@method setName
	@within ApplicationCommandOptionBuilder

	@param optionName string

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setName(self: ApplicationCommandOptionBuilder, optionName: string)
	self.optionName = optionName

	return self
end

--[=[
	@method setLocalization
	@within ApplicationCommandOptionBuilder

	@param localizationCode string

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setLocalization(self: ApplicationCommandOptionBuilder, localizationCode: string)
	self.optionLocalization = localizationCode

	return self
end

--[=[
	@method setDescription
	@within ApplicationCommandOptionBuilder

	@param optionDescription string

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setDescription(self: ApplicationCommandOptionBuilder, optionDescription: string)
	self.optionDescription = optionDescription

	return self
end

--[=[
	@method setRequired
	@within ApplicationCommandOptionBuilder

	@param isRequired boolean

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setRequired(self: ApplicationCommandOptionBuilder, isRequired: boolean)
	self.optionRequired = isRequired

	return self
end

--[=[
	@method setChannelTypes
	@within ApplicationCommandOptionBuilder

	@param channelTypes ...

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setChannelTypes(self: ApplicationCommandOptionBuilder, ...)
	for _, channelType in { ... } do
		assert(ApplicationCommandOptionBuilder.Interface.ChannelType:Is(channelType), `Expected 'channelType' to of enum 'ChannelType'`)
	end

	self.optionChannelTypes = { ... }

	return self
end

--[=[
	@method setMinValue
	@within ApplicationCommandOptionBuilder

	@param minValue number

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setMinValue(self: ApplicationCommandOptionBuilder, minValue: number)
	self.optionMinValue = minValue

	return self
end

--[=[
	@method setMaxValue
	@within ApplicationCommandOptionBuilder

	@param maxValue number

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setMaxValue(self: ApplicationCommandOptionBuilder, maxValue: number)
	self.optionMaxValue = maxValue

	return self
end

--[=[
	@method setMinLength
	@within ApplicationCommandOptionBuilder

	@param minLength number

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setMinLength(self: ApplicationCommandOptionBuilder, minLength: number)
	self.optionMinLength = minLength

	return self
end

--[=[
	@method setMaxLength
	@within ApplicationCommandOptionBuilder

	@param maxLength number

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setMaxLength(self: ApplicationCommandOptionBuilder, maxLength: number)
	self.optionMaxLength = maxLength

	return self
end

--[=[
	@method setAutocompleteEnabled
	@within ApplicationCommandOptionBuilder

	@param autocomplete boolean

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.setAutocompleteEnabled(self: ApplicationCommandOptionBuilder, autocomplete: boolean)
	self.optionAutocomplete = autocomplete

	return self
end

--[=[
	@method addOption
	@within ApplicationCommandOptionBuilder

	@param commandOption ApplicationCommandOptionBuilder

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.addOption(self: ApplicationCommandOptionBuilder, commandOption: ApplicationCommandOptionBuilder)
	table.insert(self.options, commandOption)

	return self
end

--[=[
	@method addChoice
	@within ApplicationCommandOptionBuilder

	@param choiceName string
	@param choiceValue any

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.addChoice(self: ApplicationCommandOptionBuilder, choiceName: string, choiceValue: any)
	self.choices[choiceName] = choiceValue

	return self
end

--[=[
	@method toJSONObject
	@within ApplicationCommandOptionBuilder

	@return { ... }

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Prototype.toJSONObject(self: ApplicationCommandOptionBuilder)
	local options = {}
	local choices = {}

	for _, commandOption in self.options do
		table.insert(options, commandOption:toJSONObject())
	end

	for choiceName, choiceValue in self.choices do
		table.insert(choices, {
			name = choiceName,
			value = choiceValue,
			name_localizations = self.optionLocalization
		})
	end

	return {
		type = self.optionType,
		name = self.optionName,
		description = self.optionDescription,

		required = self.optionRequired,

		name_localizations = self.optionLocalization,
		description_localizations = self.optionLocalization,

		options = options,
		choices = choices,

		channel_types = self.optionChannelTypes,

		min_value = self.optionMinValue,
		max_value = self.optionMaxValue,

		min_length = self.optionMinLength,
		max_length = self.optionMaxLength,

		autocomplete = self.optionAutocomplete
	}
end

--[=[
	@function new
	@within ApplicationCommandOptionBuilder

	@return ApplicationCommandOptionBuilder

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptionBuilder.Interface.new(): ApplicationCommandOptionBuilder
	return Construct({
		choices = {},
		options = {}
	}, ApplicationCommandOptionBuilder.Prototype) :: any
end

export type ApplicationCommandOptionBuilder = typeof(ApplicationCommandOptionBuilder.Prototype) & {
	optionAutocomplete: boolean,

	optionMaxLength: number,
	optionMinLength: number,

	optionMaxValue: number,
	optionMinValue: number,

	optionLocalization: string,
	optionRequired: boolean,

	optionDescription: string,
	optionName: string,

	optionType: number,

	optionChannelTypes: { number },

	choices: { [string]: string },
	options: { ApplicationCommandOptionBuilder }
}

return ApplicationCommandOptionBuilder.Interface