--[[
	Implementation of discords ActionRow object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#action-rows
]]

local button = require("./button")
local textInput = require("./textInput")
local selectMenu = require("./selectMenu/selectMenu")

local ActionRow = {}

ActionRow.Prototype = {}
ActionRow.Interface = {}

--[[
	
]]
function ActionRow.Prototype.addComponent(
	self: ActionRow,
	component: button.JSON | textInput.JSON | selectMenu.JSON | JSON
): ActionRow
	table.insert(self.components, component)

	return self
end

--[[
	Responsible for building the ActionRow JSON that can be parsed by the Discord API.
]]
function ActionRow.Prototype.build(self: ActionRow): JSON
	return {
		type = 1,
		components = self.components,
	}
end

--[[
	Responsible for creating a new ActionRow.

	```lua
	
	```
]]
function ActionRow.Interface.new(resource: {
	components: { button.JSON | textInput.JSON | selectMenu.JSON | JSON },
}?): ActionRow
	local self = setmetatable(
		{
			components = {},
		} :: ActionRow,
		{
			__index = ActionRow.Prototype,
		}
	)

	if resource then
		if resource.components then
			for _, component in resource.components do
				self:addComponent(component)
			end
		end
	end

	return self
end

export type ActionRow = typeof(ActionRow.Prototype) & {
	components: { button.JSON | textInput.JSON | selectMenu.JSON | JSON },
}

export type JSON = typeof(ActionRow.Prototype.build(nil :: any))

return ActionRow.Interface
