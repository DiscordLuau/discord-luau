local Construct = require("../../Utils/Construct")

local ButtonComponent = require("ButtonComponent")
local SelectionComponent = require("SelectionComponent")
local TextInputComponent = require("TextInputComponent")

--[=[
	@class Interface.ActionRowComponent

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local ActionRowComponent = {}

ActionRowComponent.Interface = {}
ActionRowComponent.Prototype = {}

ActionRowComponent.Prototype.type = "ActionRowComponent"

function ActionRowComponent.Prototype.addComponent(
	self: ActionRowComponent,
	componentObject: ActionRowComponent
		| ButtonComponent.ButtonComponent
		| SelectionComponent.SelectionComponent
		| TextInputComponent.TextInputComponent
): ActionRowComponent
	assert(#self.components + 1 <= 5, "Action Row objects can only contain up to five components!")

	table.insert(self.components, componentObject)

	return self
end

function ActionRowComponent.Prototype.toJSONObject(self: ActionRowComponent)
	local components = {}

	for index, componentObject in self.components do
		components[index] = componentObject:toJSONObject()
	end

	return {
		type = 1,
		components = components
	}
end

function ActionRowComponent.Interface.new()
	return Construct({
		components = { }
	}, ActionRowComponent.Prototype)
end

export type ActionRowComponent = typeof(ActionRowComponent.Prototype) & {

}

return ActionRowComponent.Interface