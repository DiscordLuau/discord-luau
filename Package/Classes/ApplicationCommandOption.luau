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

function ApplicationCommandOptions.Prototype.setType(self: ApplicationCommandOptions, optionType: string)
	assert(ApplicationCommandOptions.Interface.Type:Is(optionType), `Expected 'optionType' to of enum 'OptionType'`)

	self.OptionType = optionType

	return self
end

function ApplicationCommandOptions.Prototype.setName(self: ApplicationCommandOptions, optionName: string)
	self.OptionName = optionName

	return self
end

function ApplicationCommandOptions.Prototype.setLocalization(self: ApplicationCommandOptions, localizationCode: string)
	self.OptionLocalization = localizationCode

	return self
end

function ApplicationCommandOptions.Prototype.setDescription(self: ApplicationCommandOptions, optionDescription: string)
	self.OptionDescription = optionDescription

	return self
end

function ApplicationCommandOptions.Prototype.setRequired(self: ApplicationCommandOptions, isRequired: boolean)
	self.OptionRequired = isRequired

	return self
end

function ApplicationCommandOptions.Prototype.setChannelTypes(self: ApplicationCommandOptions, ...)
	for _, channelType in { ... } do
		assert(ApplicationCommandOptions.Interface.ChannelType:Is(channelType), `Expected 'channelType' to of enum 'ChannelType'`)
	end

	self.OptionChannelTypes = { ... }

	return self
end

function ApplicationCommandOptions.Prototype.setMinValue(self: ApplicationCommandOptions, minValue: number)
	self.OptionMinValue = minValue

	return self
end

function ApplicationCommandOptions.Prototype.setMaxValue(self: ApplicationCommandOptions, maxValue: number)
	self.OptionMaxValue = maxValue

	return self
end

function ApplicationCommandOptions.Prototype.setMinLength(self: ApplicationCommandOptions, minLength: number)
	self.OptionMinLength = minLength

	return self
end

function ApplicationCommandOptions.Prototype.setMaxLength(self: ApplicationCommandOptions, maxLength: number)
	self.OptionMaxLength = maxLength

	return self
end

function ApplicationCommandOptions.Prototype.setAutocompleteEnabled(self: ApplicationCommandOptions, autocomplete: boolean)
	self.OptionAutocomplete = autocomplete

	return self
end

function ApplicationCommandOptions.Prototype.addOption(self: ApplicationCommandOptions, commandOption: ApplicationCommandOptions)
	table.insert(self.Options, commandOption)

	return self
end

function ApplicationCommandOptions.Prototype.destroyOption(self: ApplicationCommandOptions, optionName: string)
	for index, commandObject in self.Options do
		if commandObject.OptionName ~= optionName then
			continue
		end

		table.remove(self.Choices, index)

		return self
	end

	return self
end

function ApplicationCommandOptions.Prototype.addChoice(self: ApplicationCommandOptions, choiceName: string, choiceValue: string)
	self.Choices[choiceName] = choiceValue

	return self
end

function ApplicationCommandOptions.Prototype.destroyChoice(self: ApplicationCommandOptions, choiceName: string)
	self.Choices[choiceName] = nil

	return self
end

function ApplicationCommandOptions.Prototype.toJSONObject(self: ApplicationCommandOptions)
	local options = {}
	local choices = {}

	for _, commandOption in self.Options do
		table.insert(options, commandOption:toJSONObject())
	end

	for choiceName, choiceValue in self.Choices do
		table.insert(choices, {
			name = choiceName,
			value = choiceValue,
			name_localizations = self.OptionLocalization
		})
	end

	return {
		type = self.OptionType,
		name = self.OptionName,
		description = self.OptionDescription,

		required = self.OptionRequired,

		name_localizations = self.OptionLocalization,
		description_localizations = self.OptionLocalization,

		options = options,
		choices = choices,

		channel_types = self.OptionChannelTypes,

		min_value = self.OptionMinValue,
		max_value = self.OptionMaxValue,

		min_length = self.OptionMinLength,
		max_length = self.OptionMaxLength,

		autocomplete = self.OptionAutocomplete
	}
end

function ApplicationCommandOptions.Interface.new()
	return Construct({
		Choices = {},
		Options = {}
	}, ApplicationCommandOptions.Prototype)
end

export type ApplicationCommandOptions = typeof(ApplicationCommandOptions.Interface.new())

return ApplicationCommandOptions.Interface