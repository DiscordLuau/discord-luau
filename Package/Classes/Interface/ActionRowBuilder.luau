local Construct = require("../../Utils/Construct")

local ButtonBuilder = require("ButtonBuilder")
local SelectionBuilder = require("SelectionBuilder")
local TextInputBuilder = require("TextInputBuilder")

--[=[
	@class Interface.ActionRowBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local ActionRowBuilder = {}

ActionRowBuilder.Interface = {}
ActionRowBuilder.Prototype = {}

ActionRowBuilder.Prototype.type = "ActionRowBuilder"

function ActionRowBuilder.Prototype.addComponent(
	self: ActionRowBuilder,
	componentObject: ActionRowBuilder
		| ButtonBuilder.ButtonBuilder
		| SelectionBuilder.SelectionBuilder
		| TextInputBuilder.TextInputBuilder
): ActionRowBuilder
	assert(#self.components + 1 <= 5, "Action Row objects can only contain up to five components!")

	table.insert(self.components, componentObject)

	return self
end

function ActionRowBuilder.Prototype.toJSONObject(self: ActionRowBuilder)
	local components = {}

	for index, componentObject in self.components :: { any } do
		components[index] = componentObject:toJSONObject()
	end

	return {
		type = 1,
		components = components
	}
end

function ActionRowBuilder.Interface.new(): ActionRowBuilder
	return Construct({
		components = { }
	}, ActionRowBuilder.Prototype)
end

export type ActionRowBuilder = typeof(ActionRowBuilder.Prototype) & {
	components: {
		ActionRowBuilder
		| ButtonBuilder.ButtonBuilder
		| SelectionBuilder.SelectionBuilder
		| TextInputBuilder.TextInputBuilder
	}
}

return ActionRowBuilder.Interface