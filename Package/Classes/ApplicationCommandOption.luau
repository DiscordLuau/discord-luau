local Enumerate = require("../Utils/Enumerate")
local Construct = require("../Utils/Construct")

--[=[
	@class ApplicationCommandOptions

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local ApplicationCommandOptions = {}

ApplicationCommandOptions.Interface = {}
ApplicationCommandOptions.Prototype = {}

ApplicationCommandOptions.Prototype.type = "ApplicationCommandOptions"

--[=[
	@prop Type { ... }
	@within ApplicationCommandOptions
]=]
ApplicationCommandOptions.Interface.Type = Enumerate.new({
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
	@within ApplicationCommandOptions
]=]
ApplicationCommandOptions.Interface.ChannelType = Enumerate.new({
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
	@within ApplicationCommandOptions

	@param optionType string

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setType(self: ApplicationCommandOptions, optionType: string)
	assert(ApplicationCommandOptions.Interface.Type:Is(optionType), `Expected 'optionType' to of enum 'optionType'`)

	self.optionType = optionType

	return self
end

--[=[
	@method setName
	@within ApplicationCommandOptions

	@param optionName string

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setName(self: ApplicationCommandOptions, optionName: string)
	self.optionName = optionName

	return self
end

--[=[
	@method setLocalization
	@within ApplicationCommandOptions

	@param localizationCode string

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setLocalization(self: ApplicationCommandOptions, localizationCode: string)
	self.optionLocalization = localizationCode

	return self
end

--[=[
	@method setDescription
	@within ApplicationCommandOptions

	@param optionDescription string

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setDescription(self: ApplicationCommandOptions, optionDescription: string)
	self.optionDescription = optionDescription

	return self
end

--[=[
	@method setRequired
	@within ApplicationCommandOptions

	@param isRequired boolean

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setRequired(self: ApplicationCommandOptions, isRequired: boolean)
	self.optionRequired = isRequired

	return self
end

--[=[
	@method setChannelTypes
	@within ApplicationCommandOptions

	@param channelTypes ...

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setChannelTypes(self: ApplicationCommandOptions, ...)
	for _, channelType in { ... } do
		assert(ApplicationCommandOptions.Interface.ChannelType:Is(channelType), `Expected 'channelType' to of enum 'ChannelType'`)
	end

	self.optionChannelTypes = { ... }

	return self
end

--[=[
	@method setMinValue
	@within ApplicationCommandOptions

	@param minValue number

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setMinValue(self: ApplicationCommandOptions, minValue: number)
	self.optionMinValue = minValue

	return self
end

--[=[
	@method setMaxValue
	@within ApplicationCommandOptions

	@param maxValue number

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setMaxValue(self: ApplicationCommandOptions, maxValue: number)
	self.optionMaxValue = maxValue

	return self
end

--[=[
	@method setMinLength
	@within ApplicationCommandOptions

	@param minLength number

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setMinLength(self: ApplicationCommandOptions, minLength: number)
	self.optionMinLength = minLength

	return self
end

--[=[
	@method setMaxLength
	@within ApplicationCommandOptions

	@param maxLength number

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setMaxLength(self: ApplicationCommandOptions, maxLength: number)
	self.optionMaxLength = maxLength

	return self
end

--[=[
	@method setAutocompleteEnabled
	@within ApplicationCommandOptions

	@param autocomplete boolean

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.setAutocompleteEnabled(self: ApplicationCommandOptions, autocomplete: boolean)
	self.optionAutocomplete = autocomplete

	return self
end

--[=[
	@method addOption
	@within ApplicationCommandOptions

	@param commandOption ApplicationCommandOptions

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.addOption(self: ApplicationCommandOptions, commandOption: ApplicationCommandOptions)
	table.insert(self.Options, commandOption)

	return self
end

--[=[
	@method addChoice
	@within ApplicationCommandOptions

	@param choiceName string
	@param choiceValue any

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.addChoice(self: ApplicationCommandOptions, choiceName: string, choiceValue: any)
	self.choices[choiceName] = choiceValue

	return self
end

--[=[
	@method toJSONObject
	@within ApplicationCommandOptions

	@return { ... }

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Prototype.toJSONObject(self: ApplicationCommandOptions)
	local options = {}
	local choices = {}

	for _, commandOption in self.Options do
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
	@within ApplicationCommandOptions

	@return ApplicationCommandOptions

	(yet-to-do!)

	```lua

	```
]=]
function ApplicationCommandOptions.Interface.new()
	return Construct({
		choices = {},
		Options = {}
	}, ApplicationCommandOptions.Prototype)
end

export type ApplicationCommandOptions = typeof(ApplicationCommandOptions.Interface.new())

return ApplicationCommandOptions.Interface