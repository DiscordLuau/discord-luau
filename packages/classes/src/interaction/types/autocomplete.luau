--[[
	Implementation of the Discord Autocomplete Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

local apiTypes = require("@api-types/apiTypes")

local interactionBehaviour = require("@classes/interaction/behaviour/interaction")

-- selene: allow(unused_variable)
local state = require("@classes/state")

local Autocomplete = {}

Autocomplete.Interface = {}
Autocomplete.Prototype = {}
Autocomplete.Behaviours = {
	interactionBehaviour,
}

function Autocomplete.Prototype.sync(self: Autocomplete, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Autocomplete.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

function Autocomplete.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Autocomplete
	local self = setmetatable(
		{
			state = state,
		} :: Autocomplete,
		{ __index = Autocomplete.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Autocomplete = typeof(Autocomplete.Prototype) & interactionBehaviour.Interaction

return Autocomplete.Interface
