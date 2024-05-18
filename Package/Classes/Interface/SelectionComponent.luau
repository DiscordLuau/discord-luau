local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class Interface.SelectionComponent

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local SelectionComponent = {}

SelectionComponent.Interface = {}
SelectionComponent.Prototype = {}

SelectionComponent.Prototype.type = "SelectionComponent"

SelectionComponent.Interface.Type = Enumerate.new({
	TextSelection = 3,
	UserSelection = 5,
	RoleSelection = 6,
	MentionableSelection = 7,
	ChannelSelection = 8
})

SelectionComponent.Interface.ChannelType = Enumerate.new({
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

function SelectionComponent.Prototype.setType(self: SelectionComponent, selectionType: number): SelectionComponent
	self.selectionType = selectionType

	return self
end

function SelectionComponent.Prototype.setChannelTypes(self: SelectionComponent, ...): SelectionComponent
	self.selectionChannelTypes = { ... }

	return self
end

function SelectionComponent.Prototype.setPlaceholder(self: SelectionComponent, placeholderText: string): SelectionComponent
	self.selectionPlaceholder = placeholderText

	return self
end

function SelectionComponent.Prototype.setDisabled(self: SelectionComponent, isDisabled: boolean): SelectionComponent
	self.selectionDisabled = isDisabled

	return self
end

function SelectionComponent.Prototype.setMinValues(self: SelectionComponent, minValue: number): SelectionComponent
	self.selectionMinValue = minValue

	return self
end

function SelectionComponent.Prototype.setMaxValues(self: SelectionComponent, maxValue: number): SelectionComponent
	self.selectionMaxValue = maxValue

	return self
end

function SelectionComponent.Prototype.addChoice(
	self: SelectionComponent,
	choiceName: string,
	choiceValue: string,
	choiceDescription: string,
	isDefault: boolean,
	emojiId: string?,
	emojiName: string?
): SelectionComponent
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

function SelectionComponent.Prototype.destroyChoice(self: SelectionComponent, choiceName: string): SelectionComponent
	self.choices[choiceName] = nil

	return self
end

function SelectionComponent.Prototype.toJSONObject(self: SelectionComponent)
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

function SelectionComponent.Interface.new(selectionId: string): SelectionComponent
	return Construct({
		selectionId = selectionId,
		choices = {}
	}, SelectionComponent.Prototype) :: any
end

export type SelectionComponent = typeof(SelectionComponent.Prototype) & {
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

return SelectionComponent.Interface