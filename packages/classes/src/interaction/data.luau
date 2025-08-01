--[=[
	@class Classes.Data
	@__index Prototype

	Implementation of the Discord Data class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-data
]=]

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

--[=[
	@within Classes.Data
	@private

	Responsible for syncing data to this interaction data object. This is typically called by the API when this object is
	created or updated.
]=]
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

	--[=[
		@prop type string
		@within Classes.Data

		The type of interaction this data object represents. This is a string representation of the interaction type.
	]=]
	self.type = apiTypes.interaction.InteractionType[dataObject.type]

	--[=[
		@prop id string
		@within Classes.Data

		The unique identifier for this interaction data object.
	]=]
	self.id = dataObject.id

	--[=[
		@prop name string
		@within Classes.Data

		The name of the interaction, typically representing the command or component name.
	]=]
	self.name = dataObject.name

	--[=[
		@prop options { Classes.DataOption }
		@within Classes.Data

		An array of data options associated with this interaction. Contains the parsed arguments or choices.
	]=]
	self.options = optionArray

	--[=[
		@prop resolved Classes.Resolved?
		@within Classes.Data

		Contains resolved objects from the interaction data, such as users, members, roles, or channels.
	]=]
	self.resolved = dataObject.resolved and resolved.new(self.state, dataObject.resolved)

	--[=[
		@prop guildId string?
		@within Classes.Data

		The ID of the guild where the interaction occurred. Will be nil for DM interactions.
	]=]
	self.guildId = dataObject.guild_id

	--[=[
		@prop targetId string?
		@within Classes.Data

		The ID of the targeted entity in the interaction, if applicable.
	]=]
	self.targetId = dataObject.target_id

	--[=[
		@prop customId string?
		@within Classes.Data

		The custom identifier for this interaction, used primarily with message components.
	]=]
	self.customId = dataObject.custom_id

	--[=[
		@prop componentType string?
		@within Classes.Data

		The type of component this interaction represents, if it's a component interaction.
	]=]
	self.componentType = apiTypes.interaction.ComponentTypes[dataObject.component_type]

	--[=[
		@prop components { Classes.Button | Classes.TextInput | Classes.SelectMenu | Classes.ActionRow }?
		@within Classes.Data

		An array of component objects that were included in this interaction.
	]=]
	self.components = componentsArray
end

--[=[
	@within Classes.Data
	@private

	Responsible for constructing this class.
]=]
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
