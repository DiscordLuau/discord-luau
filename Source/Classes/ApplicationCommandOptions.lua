local Enumeration = require("../Dependencies/Enumeration")

local ApplicationCommandOptions = {}

ApplicationCommandOptions.Type = "ApplicationCommandOptions"

ApplicationCommandOptions.Internal = {}
ApplicationCommandOptions.Interface = {}
ApplicationCommandOptions.Prototype = {
	Internal = ApplicationCommandOptions.Internal,
}

ApplicationCommandOptions.Interface.Type = Enumeration.new({
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

ApplicationCommandOptions.Interface.ChannelType = Enumeration.new({
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

function ApplicationCommandOptions.Prototype:SetType(optionType)
	assert(ApplicationCommandOptions.Interface.Type:Is(optionType), `Expected 'optionType' to of class 'OptionType'`)

	self.OptionType = optionType

	return self
end

function ApplicationCommandOptions.Prototype:SetName(optionName)
	self.OptionName = optionName

	return self
end

function ApplicationCommandOptions.Prototype:SetLocalization(localizationCode)
	self.OptionLocalization = localizationCode

	return self
end

function ApplicationCommandOptions.Prototype:SetDescription(optionDescription)
	self.OptionDescription = optionDescription

	return self
end

function ApplicationCommandOptions.Prototype:SetRequired(isRequired)
	self.OptionRequired = isRequired

	return self
end

function ApplicationCommandOptions.Prototype:SetChannelTypes(...)
	self.OptionChannelTypes = { ... }

	return self
end

function ApplicationCommandOptions.Prototype:SetMinValue(minValue)
	self.OptionMinValue = minValue

	return self
end

function ApplicationCommandOptions.Prototype:SetMaxValue(maxValue)
	self.OptionMaxValue = maxValue

	return self
end

function ApplicationCommandOptions.Prototype:SetMinLength(minLength)
	self.OptionMinLength = minLength

	return self
end

function ApplicationCommandOptions.Prototype:SetMaxLength(maxLength)
	self.OptionMaxLength = maxLength

	return self
end

function ApplicationCommandOptions.Prototype:SetAutocompleteEnabled(autocomplete)
	self.OptionAutocomplete = autocomplete

	return self
end

function ApplicationCommandOptions.Prototype:AddOption(commandOption)
	table.insert(self.Options, commandOption)

	return self
end

function ApplicationCommandOptions.Prototype:DestroyOption(optionName)
	for index, commandObject in self.Options do
		if commandObject.OptionName ~= optionName then
			continue
		end

		table.remove(self.Choices, index)

		return self
	end

	return self
end

function ApplicationCommandOptions.Prototype:AddChoice(choiceName, choiceValue)
	self.Choices[choiceName] = choiceValue

	return self
end

function ApplicationCommandOptions.Prototype:DestroyChoice(choiceName)
	self.Choices[choiceName] = nil

	return self
end

function ApplicationCommandOptions.Prototype:ToJSONObject()
	local options = {}
	local choices = {}

	for _, commandOption in self.Options do
		table.insert(options, commandOption:ToJSONObject())
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

function ApplicationCommandOptions.Prototype:ToString()
	return `{ApplicationCommandOptions.Type}<{self.Name or "Unknown Command"}>`
end

function ApplicationCommandOptions.Interface.new()
	return setmetatable({
		Choices = {},
		Options = {}
	}, {
		__index = ApplicationCommandOptions.Prototype,
		__type = ApplicationCommandOptions.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return ApplicationCommandOptions.Interface
