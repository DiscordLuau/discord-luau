--[[
	Implementation of the Discord Modal Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

local apiTypes = require("@api-types/apiTypes")

local interactionBehaviour = require("@classes/interaction/behaviour/interaction")

-- selene: allow(unused_variable)
local state = require("@classes/state")

local Modal = {}

Modal.Interface = {}
Modal.Prototype = {}
Modal.Behaviours = {
	interactionBehaviour,
}

function Modal.Prototype.sync(self: Modal, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Modal.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

function Modal.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Modal
	local self = setmetatable(
		{
			state = state,
		} :: Modal,
		{ __index = Modal.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Modal = typeof(Modal.Prototype) & interactionBehaviour.Interaction

return Modal.Interface
