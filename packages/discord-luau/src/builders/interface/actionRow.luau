local construct = require("@util/construct")

local Resolvable = require("@network/resolvable")

local ButtonBuilder = require("button")
local SelectionBuilder = require("selection")
local TextInputBuilder = require("textInput")

local ResolvableType = require("@enums/resolvableType")

--[=[
	@class Builders.Interface.ActionRowBuilder

	ActionRowBuilder is used to construct an action row, which can contain up to five components like buttons, selections, or text inputs.
]=]
local ActionRowBuilder = {}

ActionRowBuilder.Interface = {}
ActionRowBuilder.Prototype = {}

ActionRowBuilder.Prototype.type = "ActionRowBuilder"

--[=[
	Adds a component to the action row. The action row can contain up to five components.
	
	@private
	@method addComponent
	@param componentObject ActionRowBuilder | ButtonBuilder | SelectionBuilder | TextInputBuilder -- The component to be added.
	@within Builders.Interface.ActionRowBuilder
	@return Builders.Interface.ActionRowBuilder -- Returns the ActionRowBuilder instance for method chaining.
]=]
function ActionRowBuilder.Prototype.addComponent(
	self: ActionRowBuilder,
	componentObject: ActionRowBuilder | ButtonBuilder.ButtonBuilder | SelectionBuilder.SelectionBuilder | TextInputBuilder.TextInputBuilder
): ActionRowBuilder
	assert(#self.components + 1 <= 5, "Action Row objects can only contain up to five components!")

	table.insert(self.components, componentObject)

	return self
end

--[=[
	Converts the action row to a JSON object that can be sent to the Discord API.
	
	@private
	@method toPayloadObject
	@within Builders.Interface.ActionRowBuilder
	@return Network.Resolvable
]=]
function ActionRowBuilder.Prototype.toPayloadObject(self: ActionRowBuilder)
	local components = {}

	for index, componentObject in self.components :: { any } do
		components[index] = componentObject:toPayloadObject():resolve()
	end

	return Resolvable.new(ResolvableType.JSON, {
		type = 1,
		components = components,
	})
end

--[=[
	Creates a new instance of ActionRowBuilder.
	
	@private
	@function new
	@within Builders.Interface.ActionRowBuilder
	@return Builders.Interface.ActionRowBuilder -- A new instance of ActionRowBuilder.
]=]
function ActionRowBuilder.Interface.new(): ActionRowBuilder
	return construct({
		components = {},
	}, ActionRowBuilder.Prototype)
end

export type ActionRowBuilder = typeof(ActionRowBuilder.Prototype) & {
	components: {
		ActionRowBuilder
		| ButtonBuilder.ButtonBuilder
		| SelectionBuilder.SelectionBuilder
		| TextInputBuilder.TextInputBuilder
	},
}

return ActionRowBuilder.Interface
