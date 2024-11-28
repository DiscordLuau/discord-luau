--[[
	Implementation of the Discord ActionRow class in Luau

	https://discord.com/developers/docs/resources/message#message-object-message-activity-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local button = require("./button")
local textInput = require("./textInput")
local selectMenu = require("./selectMenu/selectMenu")

local ActionRow = {}

ActionRow.Interface = {}
ActionRow.Prototype = {}

function ActionRow.Prototype.sync(self: ActionRow, activityObject: apiTypes.ActionRowComponentObject)
	local components: { button.Button | textInput.TextInput | selectMenu.SelectMenu | ActionRow } = {}

	for _, componentData in activityObject.components do
		if componentData.type == 1 then
			local data = componentData :: apiTypes.ActionRowComponentObject

			table.insert(components, ActionRow.Interface.new(data))
		elseif componentData.type == 2 then
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
	self.components = components
end

function ActionRow.Interface.new(activityObject: apiTypes.ActionRowComponentObject): ActionRow
	local self = setmetatable({} :: ActionRow, { __index = ActionRow.Prototype })

	self:sync(activityObject)

	return self
end

export type ActionRow = typeof(ActionRow.Prototype) & {
	type: number,
	components: { button.Button | textInput.TextInput | selectMenu.SelectMenu | ActionRow },
}

return ActionRow.Interface
