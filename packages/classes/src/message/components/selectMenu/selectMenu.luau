--[[
	Implementation of the Discord SelectMenu class in Luau

	https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-menu-structure
]]

local apiTypes = require("@api-types/apiTypes")
local channelTypes = require("@api-types/channel")

local option = require("@classes/message/components/selectMenu/option")
local defaultValue = require("@classes/message/components/selectMenu/defaultValue")

local SelectMenu = {}

SelectMenu.Interface = {}
SelectMenu.Prototype = {}

function SelectMenu.Prototype.sync(self: SelectMenu, selectMenuData: apiTypes.SelectMenuComponentObject)
	local optionArray = {}
	local defaultValues = {}
	local channelTypesArray: { channelTypes.ChannelType } = {}

	for _, optionData in next, selectMenuData.options or {} do
		table.insert(optionArray, option.new(optionData))
	end

	for _, defaultValueData in next, selectMenuData.default_values or {} do
		table.insert(defaultValues, defaultValue.new(defaultValueData))
	end

	for _, channelType in next, selectMenuData.channel_types or {} do
		table.insert(
			channelTypesArray,
			(
					channelType == 0 and "GuildText"
					or channelType == 1 and "DM"
					or channelType == 2 and "GuildVoice"
					or channelType == 3 and "GroupDM"
					or channelType == 4 and "GuildCategory"
					or channelType == 5 and "GuildAnnouncement"
					or channelType == 10 and "AnnouncementThread"
					or channelType == 11 and "PublicThread"
					or channelType == 12 and "PrivateThread"
					or channelType == 13 and "GuildStageVoice"
					or channelType == 14 and "GuildDirectory"
					or channelType == 15 and "GuildForum"
					or channelType == 16 and "GuildMedia"
					or nil
				) :: channelTypes.ChannelType
		)
	end

	self.type = selectMenuData.type
	self.customId = selectMenuData.custom_id
	self.options = optionArray
	self.channelTypes = channelTypesArray
	self.placeholder = selectMenuData.placeholder
	self.defaultValues = defaultValues
	self.minValues = selectMenuData.min_values
	self.maxValues = selectMenuData.max_values
	self.disabled = selectMenuData.disabled
end

function SelectMenu.Interface.new(selectMenuData: apiTypes.SelectMenuComponentObject): SelectMenu
	local self = setmetatable({} :: SelectMenu, { __index = SelectMenu.Prototype })

	self:sync(selectMenuData)

	return self
end

export type SelectMenu = typeof(SelectMenu.Prototype) & {
	type: number,
	customId: string,
	options: { option.Option }?,
	channelTypes: { channelTypes.ChannelType }?,
	placeholder: string?,
	defaultValues: { defaultValue.DefaultValue }?,
	minValues: number?,
	maxValues: number?,
	disabled: boolean?,
}

return SelectMenu.Interface
