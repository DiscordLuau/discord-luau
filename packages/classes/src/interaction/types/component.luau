--[[
	Implementation of the Discord Component Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

local apiTypes = require("@api-types/apiTypes")

local interactionBehaviour = require("@classes/interaction/behaviour/interaction")

-- selene: allow(unused_variable)
local state = require("@classes/state")

local Component = {}

Component.Interface = {}
Component.Prototype = {}
Component.Behaviours = {
	interactionBehaviour,
}

function Component.Prototype.sync(self: Component, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Component.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

function Component.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Component
	local self = setmetatable(
		{
			state = state,
		} :: Component,
		{ __index = Component.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Component = typeof(Component.Prototype) & interactionBehaviour.Interaction

return Component.Interface
