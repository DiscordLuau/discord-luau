local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

local ResolvableType = require("../../Enums/ResolveableType")
local Resolvable = require("../Network/Resolvable")

--[=[
	@class Builders.CommandOptionBuilder

	CommandOptionBuilder is used to construct options for a Discord application command, including type, name, description, and choices.

	Usage:
	```lua
	local option = CommandOptionBuilder.new()
		:setType(CommandOptionBuilder.Type.String)
		:setName("example_option")
		:setDescription("This is an example option.")
		:setRequired(true)
		:addChoice("Choice 1", "value1")
		:addChoice("Choice 2", "value2")
	```
]=]
local CommandOptionBuilder = {}

CommandOptionBuilder.Interface = {}
CommandOptionBuilder.Prototype = {}

CommandOptionBuilder.Prototype.type = "CommandOptionBuilder"

--[=[
	@prop Type table
	@within Builders.CommandOptionBuilder

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
CommandOptionBuilder.Interface.Type = Enumerate.new({
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
	Attachment = 11,
})

--[=[
	@prop ChannelType table
	@within Builders.CommandOptionBuilder

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
CommandOptionBuilder.Interface.ChannelType = Enumerate.new({
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
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setType(self: CommandOptionBuilder, optionType: number)
	CommandOptionBuilder.Interface.Type:Assert(optionType)

	self.optionType = optionType

	return self
end

--[=[
	Sets the name of the option.
	
	@method setName
	@param optionName string -- The name of the option.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setName(self: CommandOptionBuilder, optionName: string)
	self.optionName = optionName

	return self
end

--[=[
	Sets the localization code for the option.
	
	@method setLocalization
	@param localizationCode string -- The localization code.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setLocalization(self: CommandOptionBuilder, localizationCode: string)
	self.optionLocalization = localizationCode

	return self
end

--[=[
	Sets the description of the option.
	
	@method setDescription
	@param optionDescription string -- The description of the option.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setDescription(self: CommandOptionBuilder, optionDescription: string)
	self.optionDescription = optionDescription

	return self
end

--[=[
	Sets whether the option is required.
	
	@method setRequired
	@param isRequired boolean -- Whether the option is required.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setRequired(self: CommandOptionBuilder, isRequired: boolean)
	self.optionRequired = isRequired

	return self
end

--[=[
	Sets the channel types for the option.
	
	@method setChannelTypes
	@param channelTypes ... -- The channel types.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setChannelTypes(self: CommandOptionBuilder, ...)
	for _, channelType in { ... } do
		CommandOptionBuilder.Interface.ChannelType:Assert(channelType)
	end

	self.optionChannelTypes = { ... }

	return self
end

--[=[
	Sets the minimum value for the option.
	
	@method setMinValue
	@param minValue number -- The minimum value.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setMinValue(self: CommandOptionBuilder, minValue: number)
	self.optionMinValue = minValue

	return self
end

--[=[
	Sets the maximum value for the option.
	
	@method setMaxValue
	@param maxValue number -- The maximum value.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setMaxValue(self: CommandOptionBuilder, maxValue: number)
	self.optionMaxValue = maxValue

	return self
end

--[=[
	Sets the minimum length for the option.
	
	@method setMinLength
	@param minLength number -- The minimum length.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setMinLength(self: CommandOptionBuilder, minLength: number)
	self.optionMinLength = minLength

	return self
end

--[=[
	Sets the maximum length for the option.
	
	@method setMaxLength
	@param maxLength number -- The maximum length.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setMaxLength(self: CommandOptionBuilder, maxLength: number)
	self.optionMaxLength = maxLength

	return self
end

--[=[
	Sets whether autocomplete is enabled for the option.
	
	@method setAutocompleteEnabled
	@param autocomplete boolean -- Whether autocomplete is enabled.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.setAutocompleteEnabled(self: CommandOptionBuilder, autocomplete: boolean)
	self.optionAutocomplete = autocomplete

	return self
end

--[=[
	Adds a sub-option to the option.
	
	@method addOption
	@param commandOption CommandOptionBuilder -- The sub-option to add.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.addOption(self: CommandOptionBuilder, commandOption: CommandOptionBuilder)
	table.insert(self.options, commandOption)

	return self
end

--[=[
	Adds a choice to the option.
	
	@method addChoice
	@param choiceName string -- The name of the choice.
	@param choiceValue any -- The value of the choice.
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- Returns the CommandOptionBuilder instance for method chaining.
]=]
function CommandOptionBuilder.Prototype.addChoice(self: CommandOptionBuilder, choiceName: string, choiceValue: any)
	self.choices[choiceName] = choiceValue

	return self
end

--[=[
	Converts the option to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.CommandOptionBuilder
	@return Network.Resolvable
]=]
function CommandOptionBuilder.Prototype.toPayloadObject(self: CommandOptionBuilder)
	local options = {}
	local choices = {}

	for _, commandOption in self.options do
		table.insert(options, commandOption:toPayloadObject():resolve())
	end

	for choiceName, choiceValue in self.choices do
		table.insert(choices, {
			name = choiceName,
			value = choiceValue,
			name_localizations = self.optionLocalization,
		})
	end

	return Resolvable.new(ResolvableType.JSON, {
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

		autocomplete = self.optionAutocomplete,
	})
end

--[=[
	Creates a new instance of CommandOptionBuilder.
	
	@function new
	@within Builders.CommandOptionBuilder
	@return Builders.CommandOptionBuilder -- A new instance of CommandOptionBuilder.
]=]
function CommandOptionBuilder.Interface.new()
	return (
		Construct({
			choices = {},
			options = {},
		}, CommandOptionBuilder.Prototype) :: unknown
	) :: CommandOptionBuilder
end

export type CommandOptionBuilder = typeof(CommandOptionBuilder.Prototype) & {
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
	options: { CommandOptionBuilder },
}

return CommandOptionBuilder.Interface
