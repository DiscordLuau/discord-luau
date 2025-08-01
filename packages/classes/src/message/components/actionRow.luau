--[=[
	@class Classes.ActionRow
	@__index Prototype

	Implementation of the Discord ActionRow class in Luau

	https://discord.com/developers/docs/resources/message#message-object-message-activity-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local button = require("./button")
local textInput = require("./textInput")
local selectMenu = require("./selectMenu/selectMenu")

local ActionRow = {}

ActionRow.Interface = {}
ActionRow.Prototype = {}

--[=[
	@within Classes.ActionRow
	@private

	Responsible for syncing data to this action row object. This is typically called by the API when this object is
	created or updated.
]=]
function ActionRow.Prototype.sync(self: ActionRow, activityObject: apiTypes.ActionRowComponentObject)
	--[=[
		@prop type number
		@within Classes.ActionRow

		The type of component. For action rows, this will always be 1.
	]=]
	local components: { button.Button | textInput.TextInput | selectMenu.SelectMenu } = {}

	for _, componentData in activityObject.components do
		if componentData.type == 2 then
			local data = componentData :: apiTypes.ButtonComponentObject

			table.insert(components, button.new(data))
		elseif componentData.type == 4 then
			local data = componentData :: apiTypes.TextInputComponentObject

			table.insert(components, textInput.new(data))
		elseif
			componentData.type == 3
			or componentData.type == 5
			or componentData.type == 6
			or componentData.type == 7
			or componentData.type == 8
		then
			local data = componentData :: apiTypes.SelectMenuComponentObject

			table.insert(components, selectMenu.new(data))
		end
	end

	self.type = activityObject.type

	--[=[
		@prop components {Classes.Button | Classes.TextInput | Classes.SelectMenu}
		@within Classes.ActionRow

		An array of components within this action row. Can contain buttons, text inputs, or select menus.
	]=]
	self.components = components
end

--[=[
	@within Classes.ActionRow
	@private

	Responsible for constructing this class.
]=]
function ActionRow.Interface.new(activityObject: apiTypes.ActionRowComponentObject): ActionRow
	local self = setmetatable({} :: ActionRow, { __index = ActionRow.Prototype })

	self:sync(activityObject)

	return self
end

export type ActionRow = typeof(ActionRow.Prototype) & {
	type: number,

	components: { button.Button | textInput.TextInput | selectMenu.SelectMenu },
}

return ActionRow.Interface
