--[=[
	@class Classes.Component
	@__index Prototype

	Implementation of the Discord Component Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]=]

-- selene: allow(unused_variable)
local state = require("../../../lune_packages/state")
local apiTypes = require("../../../lune_packages/api_types")

local interactionBehaviour = require("../behaviour/interaction")
local interactableBehaviour = require("../behaviour/interactable")

local Component = {}

Component.Interface = {}
Component.Prototype = {}
Component.Behaviours = {
	interactionBehaviour,
	interactableBehaviour,
}

--[=[
	@within Classes.Component
	@private

	Responsible for syncing data to this component interaction object. This is typically called by the API when this object is
	created or updated.
]=]
function Component.Prototype.sync(self: Component, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Component.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

--[=[
	@within Classes.Component
	@private

	Responsible for constructing this class.
]=]
function Component.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Component
	local self = setmetatable(
		{
			state = state,
			isDeferred = false,
		} :: Component,
		{ __index = Component.Prototype }
	)

	self:sync(interactionData)

	return self
end

--[=[
	@prop isDeferred boolean
	@within Classes.Component
]=]

--[=[
	@prop state State
	@within Classes.Component
]=]

export type Component = typeof(Component.Prototype) & {
	isDeferred: boolean,
} & interactionBehaviour.Interaction & interactableBehaviour.Interaction

return Component.Interface
