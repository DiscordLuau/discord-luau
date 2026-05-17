--[=[
	@class Classes.Interactions.Modal
	@__index Prototype
	@tag inherit:Classes.Interactions.InteractionBehaviour
	@tag inherit:Classes.Interactions.Interactable

	Implementation of the Discord Modal Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]=]

-- selene: allow(unused_variable)
local state = require("../../../luau_packages/state")
local apiTypes = require("../../../luau_packages/api_types")

local interactionBehaviour = require("../behaviour/interaction")
local interactableBehaviour = require("../behaviour/interactable")

local actionRow = require("../../message/components/actionRow")
local textInput = require("../../message/components/textInput")

local Modal = {}

Modal.Interface = {}
Modal.Prototype = {}
Modal.Behaviours = {
	interactionBehaviour,
	interactableBehaviour,
}

--[=[
	@within Classes.Interactions.Modal

	Gets the content of a text input component with the specified custom ID.
]=]
function Modal.Prototype.getContent(self: Modal, customId: string): string?
	assert(self.data, `Expected data`)
	assert(self.data.components, `Expected components`)
	assert(self.data.components[1], `Expected component list`)

	for _, componentList in self.data.components :: { actionRow.ActionRow } do
		for _, value in componentList.components :: { textInput.TextInput } do
			if value.customId == customId then
				return value.value
			end
		end
	end

	return nil
end

--[=[
	@within Classes.Interactions.Modal

	Responsible for syncing data to this modal interaction object. This is typically called by the API when this object is
	created or updated.
]=]
function Modal.Prototype.sync(self: Modal, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Modal.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

--[=[
	@within Classes.Interactions.Modal

	Responsible for constructing this class.
]=]
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

export type Modal = typeof(Modal.Prototype) & interactionBehaviour.Interaction & interactableBehaviour.Interaction

return Modal.Interface
