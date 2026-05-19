--[=[
	@class Classes.Interactions.Component
	@__index Prototype
	@tag inherit:Classes.Interactions.InteractionBehaviour
	@tag inherit:Classes.Interactions.Interactable

	Implementation of the Discord Component Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]=]

-- selene: allow(unused_variable)
local state = require("../../../luau_packages/state")
local apiTypes = require("../../../luau_packages/api_types")
local rest = require("../../../luau_packages/rest")
local future = require("../../../luau_packages/future")
local builders = require("../../../luau_packages/builders")

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
	@within Classes.Interactions.Component

	Silently acknowledge a component interaction without updating the original message. Sends interaction
	response type 6 (DEFERRED_UPDATE_MESSAGE). Use this when you want to handle the interaction in the
	background without showing a loading state or modifying the message.
]=]
function Component.Prototype.acknowledgeAsync(self: Component): future.FutureLike<string, nil>
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = 6,
			}, {
				withResponse = false,
			})
			:await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		self.isDeferred = true

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Interactions.Component

	Edit the message this component is attached to. Sends interaction response type 7 (UPDATE_MESSAGE).
	Unlike acknowledgeAsync + editResponseAsync, this updates the message immediately in a single round trip.
]=]
function Component.Prototype.updateAsync(
	self: Component,
	messageJSON: builders.messageJSON
): future.FutureLike<string, nil>
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		request:setFlag("FormdataRequest", true)

		local response = rest.interaction
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = 7,
				data = messageJSON,
			}, {
				withResponse = false,
			})
			:await()

		assert(response:isOk(), `{response:unwrapErr()}`)

		self.isDeferred = true

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Interactions.Component

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
	@within Classes.Interactions.Component

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
	@within Classes.Interactions.Component
]=]

--[=[
	@prop state State
	@within Classes.Interactions.Component
]=]

export type Component = typeof(Component.Prototype) & {
	isDeferred: boolean,
} & interactionBehaviour.Interaction & interactableBehaviour.Interaction

return Component.Interface
