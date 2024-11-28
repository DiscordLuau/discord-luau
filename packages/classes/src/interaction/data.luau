--[[
	Implementation of the Discord Data class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-data
]]

local apiTypes = require("../../lune_packages/api_types")

local state = require("../../lune_packages/state")

local button = require("../message/components/button")
local textInput = require("../message/components/textInput")
local selectMenu = require("../message/components/selectMenu/selectMenu")
local actionRow = require("../message/components/actionRow")

local dataOption = require("./dataOption")
local resolved = require("../resolved")

local Data = {}

Data.Interface = {}
Data.Prototype = {}

function Data.Prototype.sync(self: Data, dataObject: apiTypes.InteractionDataObject)
	local optionArray = {}
	local componentsArray: { button.Button | textInput.TextInput | selectMenu.SelectMenu | actionRow.ActionRow } = {}

	for _, option in next, dataObject.options or {} do
		table.insert(optionArray, dataOption.new(option))
	end

	if dataObject.components then
		for _, component in dataObject.components do
			if component.type == 1 then
				local actionRowComponent = component :: apiTypes.ActionRowComponentObject

				table.insert(componentsArray, actionRow.new(actionRowComponent))
			elseif component.type == 2 then
				local buttonComponent = component :: apiTypes.ButtonComponentObject

				table.insert(componentsArray, button.new(buttonComponent))
			elseif component.type == 4 then
				local textInputComponent = component :: apiTypes.TextInputComponentObject

				table.insert(componentsArray, textInput.new(textInputComponent))
			else
				local selectMenuComponent = component :: apiTypes.SelectMenuComponentObject

				table.insert(componentsArray, selectMenu.new(selectMenuComponent))
			end
		end
	end

	self.type = apiTypes.interaction.InteractionType[dataObject.type]

	self.id = dataObject.id
	self.name = dataObject.name
	self.options = optionArray
	self.resolved = dataObject.resolved and resolved.new(self.state, dataObject.resolved)
	self.guildId = dataObject.guild_id
	self.targetId = dataObject.target_id
	self.customId = dataObject.custom_id
	self.componentType = apiTypes.interaction.ComponentTypes[dataObject.component_type]
	self.components = componentsArray
end

function Data.Interface.new(state: state.State, dataObject: apiTypes.InteractionDataObject): Data
	local self = setmetatable(
		{
			state = state,
		} :: Data,
		{ __index = Data.Prototype }
	)

	self:sync(dataObject)

	return self
end

-- ensure any cyclic dependencies are also updated!
export type Data = typeof(Data.Prototype) & {
	state: state.State,

	id: apiTypes.Snowflake,
	name: string,
	type: apiTypes.InteractionType,
	resolved: resolved.Resolved?,
	options: { dataOption.DataOption<unknown> },
	guildId: apiTypes.Snowflake?,
	targetId: apiTypes.Snowflake?,
	customId: string?,
	componentType: apiTypes.ComponentTypes?,
	components: { button.Button | textInput.TextInput | selectMenu.SelectMenu | actionRow.ActionRow }?,
}

return Data.Interface
