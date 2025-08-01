--[=[
	@class Builders.ActionRow
	@__index Prototype

	Implementation of discords ActionRow object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#action-rows
]=]

local button = require("./button")
local textInput = require("./textInput")
local selectMenu = require("./selectMenu/selectMenu")

local ActionRow = {}

ActionRow.Prototype = {}
ActionRow.Interface = {}

--[=[
	@within Builders.ActionRow

	Adds a component to the action row. Components can be buttons, text inputs, or select menus.
]=]
function ActionRow.Prototype.addComponent(
	self: ActionRow,
	component: button.JSON | textInput.JSON | selectMenu.JSON | JSON
): ActionRow
	table.insert(self.components, component)

	return self
end

--[=[
	@within Builders.ActionRow

	Responsible for building the ActionRow JSON that can be parsed by the Discord API.
]=]
function ActionRow.Prototype.build(self: ActionRow): JSON
	return {
		type = 1,
		components = self.components,
	}
end

--[=[
	@within Builders.ActionRow

	Responsible for creating a new ActionRow.

	```luau
	local row = ActionRow.new()
		:addComponent(button)
		:build()
	```
]=]
function ActionRow.Interface.new(resource: {
	components: { button.JSON | textInput.JSON | selectMenu.JSON | JSON },
}?): ActionRow
	local self = setmetatable(
		{
			--[=[
				@prop components {Builders.Button | Builders.TextInput | Builders.SelectMenu}
				@within Builders.ActionRow
				The components that are part of this action row. Can include buttons, text inputs, and select menus.
			]=]
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
