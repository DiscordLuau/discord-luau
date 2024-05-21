local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class Interface.SelectionBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local SelectionBuilder = {}

SelectionBuilder.Interface = {}
SelectionBuilder.Prototype = {}

SelectionBuilder.Prototype.type = "SelectionBuilder"

SelectionBuilder.Interface.Type = Enumerate.new({
	TextSelection = 3,
	UserSelection = 5,
	RoleSelection = 6,
	MentionableSelection = 7,
	ChannelSelection = 8
})

SelectionBuilder.Interface.ChannelType = Enumerate.new({
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

function SelectionBuilder.Prototype.setType(self: SelectionBuilder, selectionType: number): SelectionBuilder
	self.selectionType = selectionType

	return self
end

function SelectionBuilder.Prototype.setChannelTypes(self: SelectionBuilder, ...): SelectionBuilder
	self.selectionChannelTypes = { ... }

	return self
end

function SelectionBuilder.Prototype.setPlaceholder(self: SelectionBuilder, placeholderText: string): SelectionBuilder
	self.selectionPlaceholder = placeholderText

	return self
end

function SelectionBuilder.Prototype.setDisabled(self: SelectionBuilder, isDisabled: boolean): SelectionBuilder
	self.selectionDisabled = isDisabled

	return self
end

function SelectionBuilder.Prototype.setMinValues(self: SelectionBuilder, minValue: number): SelectionBuilder
	self.selectionMinValue = minValue

	return self
end

function SelectionBuilder.Prototype.setMaxValues(self: SelectionBuilder, maxValue: number): SelectionBuilder
	self.selectionMaxValue = maxValue

	return self
end

function SelectionBuilder.Prototype.addChoice(
	self: SelectionBuilder,
	choiceName: string,
	choiceValue: string,
	choiceDescription: string,
	isDefault: boolean,
	emojiId: string?,
	emojiName: string?
): SelectionBuilder
	self.choices[choiceName] = {
		value = choiceValue,
		description = choiceDescription,
		default = isDefault
	}

	if emojiId and emojiName then
		self.choices[choiceName].emoji = {
			id = emojiId,
			name = emojiName
		}
	end

	return self
end

function SelectionBuilder.Prototype.destroyChoice(self: SelectionBuilder, choiceName: string): SelectionBuilder
	self.choices[choiceName] = nil

	return self
end

function SelectionBuilder.Prototype.toJSONObject(self: SelectionBuilder)
	local selectionOptions = {}

	for optionName, optionData in self.choices do
		table.insert(selectionOptions, {
			label = optionName,

			value = optionData.value,
			description = optionData.description,
			emoji = (optionData.emoji and {
				id = optionData.emoji.id,
				name = optionData.emoji.name
			}) or nil,
			default = optionData.default
		})
	end
	
	return {
		type = self.selectionType,
		custom_id = self.selectionId,

		channel_types = self.selectionChannelTypes,
		placeholder = self.selectionPlaceholder,

		min_value = self.selectionMinValue,
		max_value = self.selectionMaxValue,

		disabled = self.selectionDisabled,

		options = selectionOptions
	}
end

function SelectionBuilder.Interface.new(selectionId: string): SelectionBuilder
	return Construct({
		selectionId = selectionId,
		choices = {}
	}, SelectionBuilder.Prototype) :: any
end

export type SelectionBuilder = typeof(SelectionBuilder.Prototype) & {
	selectionType: number?,
	selectionId: string?,
	selectionChannelTypes: { number }?,
	selectionPlaceholder: string?,
	selectionMinValue: number?,
	selectionMaxValue: number?,
	selectionDisabled: boolean?,

	choices: {
		[string]: {
			value: any?,
			default: boolean?,
			description: string?,
			emoji: {
				id: string,
				name: string,
			}?
		}
	}
}

return SelectionBuilder.Interface