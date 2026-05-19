--[=[
	@class Classes.Interactions.Autocomplete
	@__index Prototype
	@tag inherit:Classes.Interactions.InteractionBehaviour

	Implementation of the Discord Autocomplete Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]=]

--[=[
	@prop state State
	@within Classes.Interactions.Autocomplete
]=]

-- selene: allow(unused_variable)
local state = require("../../../luau_packages/state")
local apiTypes = require("../../../luau_packages/api_types")
local rest = require("../../../luau_packages/rest")
local future = require("../../../luau_packages/future")
local builders = require("../../../luau_packages/builders")

local interactionBehaviour = require("../behaviour/interaction")

local Autocomplete = {}

Autocomplete.Interface = {}
Autocomplete.Prototype = {}
Autocomplete.Behaviours = {
	interactionBehaviour,
}

--[=[
	@within Classes.Interactions.Autocomplete

	Respond to an autocomplete interaction with a list of choices. Sends interaction response type 8
	(APPLICATION_COMMAND_AUTOCOMPLETE_RESULT).

	```luau
	interaction:respondAsync({
		builders.choice.new({ name = "Option A", value = "a" }):build(),
		builders.choice.new({ name = "Option B", value = "b" }):build(),
	}):await()
	```
]=]
function Autocomplete.Prototype.respondAsync(
	self: Autocomplete,
	choices: { builders.choiceJSON }
): future.FutureLike<string, nil>
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = 8,
				data = {
					choices = choices,
				},
			}, {
				withResponse = false,
			})
			:await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Interactions.Autocomplete

	Returns the option currently being typed by the user (the focused option). Searches recursively through
	subcommand and subcommand group options if needed.
]=]
function Autocomplete.Prototype.getFocusedOption(self: Autocomplete)
	if not self.data then
		return nil
	end

	local function findFocused(options)
		for _, option in options do
			if option.focused then
				return option
			end

			if option.options then
				local found = findFocused(option.options)
				if found then
					return found
				end
			end
		end

		return nil
	end

	return findFocused(self.data.options)
end

--[=[
	@within Classes.Interactions.Autocomplete

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
	@within Classes.Interactions.Autocomplete

	Responsible for constructing this class.
]=]
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
