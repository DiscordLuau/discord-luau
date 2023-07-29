local Enumeration = require("../../Dependencies/Enumeration")

local SelectionComponent = {}

SelectionComponent.Type = "SelectionComponent"

SelectionComponent.Internal = {}
SelectionComponent.Interface = {}
SelectionComponent.Prototype = {
	Internal = SelectionComponent.Internal,
}

SelectionComponent.Interface.Type = Enumeration.new({
	TextSelection = 3,
	UserSelection = 5,
	RoleSelection = 6,
	MentionableSelection = 7,
	ChannelSelection = 8
})

SelectionComponent.Interface.ChannelType = Enumeration.new({
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

function SelectionComponent.Prototype:SetType(selectionType)
	self.SelectionType = selectionType

	return self
end

function SelectionComponent.Prototype:SetChannelTypes(...)
	self.SelectionChannelTypes = { ... }

	return self
end

function SelectionComponent.Prototype:SetPlaceholder(placeholderText)
	self.SelectionPlaceholder = placeholderText

	return self
end

function SelectionComponent.Prototype:SetDisabled(isDisabled)
	self.SelectionDisabled = isDisabled

	return self
end

function SelectionComponent.Prototype:SetMinValues(minValue)
	self.SelectionMinValues = minValue

	return self
end

function SelectionComponent.Prototype:SetMaxValues(maxValue)
	self.SelectionMaxValues = maxValue

	return self
end

function SelectionComponent.Prototype:AddChoice(choiceName, choiceValue, choiceDescription, isDefault, emojiId, emojiName)
	self.Choices[choiceName] = {
		Value = choiceValue,
		Description = choiceDescription,
		Emoji = ((emojiId or emojiName) and {
			Id = emojiId,
			Name = emojiName
		}) or nil,
		Default = isDefault
	}

	return self
end

function SelectionComponent.Prototype:DestroyChoice(choiceName)
	self.Choices[choiceName] = nil

	return self
end

function SelectionComponent.Prototype:ToJSONObject()
	local selectionOptions = {}

	for optionName, optionData in self.Choices do
		table.insert(selectionOptions, {
			label = optionName,

			value = optionData.Value,
			description = optionData.Description,
			emoji = (optionData.Emoji and {
				id = optionData.Emoji.Id,
				name = optionData.Emoji.Name
			}) or nil,
			default = optionData.Default
		})
	end
	
	return {
		type = self.SelectionType,
		custom_id = self.SelectionId,

		channel_types = self.SelectionChannelTypes,
		placeholder = self.SelectionPlaceholder,

		min_values = self.SelectionMinValues,
		max_values = self.SelectionMaxValues,

		disabled = self.SelectionDisabled,

		options = selectionOptions
	}
end

function SelectionComponent.Prototype:ToString()
	return `{SelectionComponent.Type}<{self.Name or "Unknown Activity"}>`
end

function SelectionComponent.Interface.new(selectionId)
	return setmetatable({
		SelectionId = selectionId,
		Choices = {}
	}, {
		__index = SelectionComponent.Prototype,
		__type = SelectionComponent.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return SelectionComponent.Interface
