--[[
	Implementation of the Discord Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

local apiTypes = require("@api-types/apiTypes")

local interactionBehaviour = require("@classes/interaction/behaviour/interaction")

-- selene: allow(unused_variable)
local state = require("@classes/state")

local Interaction = {}

Interaction.Interface = {}
Interaction.Prototype = {}
Interaction.Behaviours = {
	interactionBehaviour,
}

function Interaction.Prototype.sync(self: Interaction, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Interaction.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

function Interaction.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Interaction
	local self = setmetatable(
		{
			state = state,
		} :: Interaction,
		{ __index = Interaction.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Interaction = typeof(Interaction.Prototype) & interactionBehaviour.Interaction

return Interaction.Interface
