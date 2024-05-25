local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class Builders.ApplicationCommandOptionBuilder

	ApplicationCommandOptionBuilder is used to construct options for a Discord application command, including type, name, description, and choices.

	Usage:
	```lua
	local option = ApplicationCommandOptionBuilder.new()
		:setType(ApplicationCommandOptionBuilder.Type.String)
		:setName("example_option")
		:setDescription("This is an example option.")
		:setRequired(true)
		:addChoice("Choice 1", "value1")
		:addChoice("Choice 2", "value2")
	```
]=]
local ApplicationCommandOptionBuilder = {}

ApplicationCommandOptionBuilder.Interface = {}
ApplicationCommandOptionBuilder.Prototype = {}

ApplicationCommandOptionBuilder.Prototype.type = "ApplicationCommandOptionBuilder"

--[=[
	@prop Type table
	@within Builders.ApplicationCommandOptionBuilder

	An enumeration of option types.

	- SubCommand: 1
	- SubCommandGroup: 2
	- String: 3
	- Integer: 4
	- Boolean: 5
	- User: 6
	- Channel: 7
	- Role: 8
	- Mentionable: 9
	- Number: 10
	- Attachment: 11
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
	@prop ChannelType table
	@within Builders.ApplicationCommandOptionBuilder

	An enumeration of channel types.

	- GuildText: 0
	- DirectMessage: 1
	- GuildVoice: 2
	- GroupDirectMessage: 3
	- GuildCategory: 4
	- GuildAnnouncement: 5
	- AnnouncementThread: 10
	- PublicThread: 11
	- PrivateThread: 12
	- GuildStageVoice: 13
	- GuildDirectory: 14
	- GuildForum: 15
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
	Sets the type of the option.
	
	@method setType
	@param optionType number -- The type of the option.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setType(self: ApplicationCommandOptionBuilder, optionType: number)
	assert(ApplicationCommandOptionBuilder.Interface.Type:Is(optionType), `Expected 'optionType' to be of enum 'optionType'`)

	self.optionType = optionType

	return self
end

--[=[
	Sets the name of the option.
	
	@method setName
	@param optionName string -- The name of the option.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setName(self: ApplicationCommandOptionBuilder, optionName: string)
	self.optionName = optionName

	return self
end

--[=[
	Sets the localization code for the option.
	
	@method setLocalization
	@param localizationCode string -- The localization code.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setLocalization(self: ApplicationCommandOptionBuilder, localizationCode: string)
	self.optionLocalization = localizationCode

	return self
end

--[=[
	Sets the description of the option.
	
	@method setDescription
	@param optionDescription string -- The description of the option.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setDescription(self: ApplicationCommandOptionBuilder, optionDescription: string)
	self.optionDescription = optionDescription

	return self
end

--[=[
	Sets whether the option is required.
	
	@method setRequired
	@param isRequired boolean -- Whether the option is required.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setRequired(self: ApplicationCommandOptionBuilder, isRequired: boolean)
	self.optionRequired = isRequired

	return self
end

--[=[
	Sets the channel types for the option.
	
	@method setChannelTypes
	@param channelTypes ... -- The channel types.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setChannelTypes(self: ApplicationCommandOptionBuilder, ...)
	for _, channelType in { ... } do
		assert(ApplicationCommandOptionBuilder.Interface.ChannelType:Is(channelType), `Expected 'channelType' to be of enum 'ChannelType'`)
	end

	self.optionChannelTypes = { ... }

	return self
end

--[=[
	Sets the minimum value for the option.
	
	@method setMinValue
	@param minValue number -- The minimum value.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setMinValue(self: ApplicationCommandOptionBuilder, minValue: number)
	self.optionMinValue = minValue

	return self
end

--[=[
	Sets the maximum value for the option.
	
	@method setMaxValue
	@param maxValue number -- The maximum value.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setMaxValue(self: ApplicationCommandOptionBuilder, maxValue: number)
	self.optionMaxValue = maxValue

	return self
end

--[=[
	Sets the minimum length for the option.
	
	@method setMinLength
	@param minLength number -- The minimum length.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setMinLength(self: ApplicationCommandOptionBuilder, minLength: number)
	self.optionMinLength = minLength

	return self
end

--[=[
	Sets the maximum length for the option.
	
	@method setMaxLength
	@param maxLength number -- The maximum length.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setMaxLength(self: ApplicationCommandOptionBuilder, maxLength: number)
	self.optionMaxLength = maxLength

	return self
end

--[=[
	Sets whether autocomplete is enabled for the option.
	
	@method setAutocompleteEnabled
	@param autocomplete boolean -- Whether autocomplete is enabled.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.setAutocompleteEnabled(self: ApplicationCommandOptionBuilder, autocomplete: boolean)
	self.optionAutocomplete = autocomplete

	return self
end

--[=[
	Adds a sub-option to the option.
	
	@method addOption
	@param commandOption ApplicationCommandOptionBuilder -- The sub-option to add.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.addOption(self: ApplicationCommandOptionBuilder, commandOption: ApplicationCommandOptionBuilder)
	table.insert(self.options, commandOption)

	return self
end

--[=[
	Adds a choice to the option.
	
	@method addChoice
	@param choiceName string -- The name of the choice.
	@param choiceValue any -- The value of the choice.
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- Returns the ApplicationCommandOptionBuilder instance for method chaining.
]=]
function ApplicationCommandOptionBuilder.Prototype.addChoice(self: ApplicationCommandOptionBuilder, choiceName: string, choiceValue: any)
	self.choices[choiceName] = choiceValue

	return self
end

--[=[
	Converts the option to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within Builders.ApplicationCommandOptionBuilder
	@return table -- The JSON representation of the option.
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
	Creates a new instance of ApplicationCommandOptionBuilder.
	
	@function new
	@within Builders.ApplicationCommandOptionBuilder
	@return Builders.ApplicationCommandOptionBuilder -- A new instance of ApplicationCommandOptionBuilder.
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
