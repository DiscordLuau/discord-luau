--[=[
	@class Classes.Autocomplete
	@__index Prototype

	Implementation of the Discord Autocomplete Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]=]

-- selene: allow(unused_variable)
local state = require("../../../lune_packages/state")
local apiTypes = require("../../../lune_packages/api_types")

local interactionBehaviour = require("../behaviour/interaction")

local Autocomplete = {}

Autocomplete.Interface = {}
Autocomplete.Prototype = {}
Autocomplete.Behaviours = {
	interactionBehaviour,
}

--[=[
	@within Classes.Autocomplete
	@private

	Responsible for syncing data to this interaction object. This is typically called by the API when this object is
	created or updated.
]=]
function Autocomplete.Prototype.sync(self: Autocomplete, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Autocomplete.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

--[=[
	@within Classes.Autocomplete
	@private

	Responsible for constructing this class.
]=]
function Autocomplete.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Autocomplete
	local self = setmetatable(
		{
			--[=[
				@prop state State
				@within Classes.Autocomplete
			]=]
			state = state,
		} :: Autocomplete,
		{ __index = Autocomplete.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Autocomplete = typeof(Autocomplete.Prototype) & interactionBehaviour.Interaction

return Autocomplete.Interface
