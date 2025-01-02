--[[
	Implementation of the Discord Component Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

-- selene: allow(unused_variable)
local state = require("../../../lune_packages/state")
local apiTypes = require("../../../lune_packages/api_types")
local future = require("../../../luau_packages/future")
local rest = require("../../../lune_packages/rest")
local builders = require("../../../lune_packages/builders")

local interactionBehaviour = require("../behaviour/interaction")
local message = require("../../message/message")

local Component = {}

Component.Interface = {}
Component.Prototype = {}
Component.Behaviours = {
	interactionBehaviour,
}

--[[
	acknowledge an interaction and edit a response later, the user sees a loading state
]]
function Component.Prototype.deferAsync(self: Component): future.Future<string, nil>
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local status, response = rest.interaction
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = 5,
				data = {},
			}, {
				withResponse = false,
			})
			:await()

		self.isDeferred = true

		assert(status == "Fulfilled", tostring(response))
	end)
end

--[[
	respond to this interaction with a message
]]
function Component.Prototype.messageAsync(
	self: Component,
	messageJSON: builders.messageJSON,
	responseMessage: boolean?
): future.Future<string, message.Message?>
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local status, response = rest.interaction
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = self.isDeferred and 5 or 4,
				data = messageJSON,
			}, {
				withResponse = responseMessage or false,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		if responseMessage and response.resource.message then
			return message.new(self.state, response.resource.message)
		end
	end)
end

--[[
	get the response created by this interaction
]]
function Component.Prototype.getResponseAsync(
	self: Component,
	threadId: string?
): future.Future<string, message.Message>
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local status, response = rest.interaction
			.getOriginalInteractionResponseAsync(request, self.id, self.token, {
				threadId = threadId,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return message.new(self.state, response)
	end)
end

--[[
	edit the response made by this interaction
]]
function Component.Prototype.editResponseAsync(
	self: Component,
	messageJSON: builders.messageJSON,
	threadId: string?
): future.Future<string, message.Message>
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local status, response = rest.interaction
			.editOriginalInteractionResponseAsync(request, self.id, self.token, messageJSON, {
				threadId = threadId,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return message.new(self.state, response)
	end)
end

--[[
	delete the original response made by this interaction
]]
function Component.Prototype.deleteResponseAsync(self: Component): future.Future<string, nil>
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local status, response =
			rest.interaction.deleteOriginalInteractionResponseAsync(request, self.id, self.token):await()

		assert(status == "Fulfilled", tostring(response))
	end)
end

--[[
	create a followup response to an interaction, followup responses are messages you can send after
	the initial response is sent.
]]
function Component.Prototype.createFollowupResponseAsync(
	self: Component,
	messageJSON: builders.messageJSON,
	threadId: string?
)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local status, response = rest.interaction
			.createFollowupMessageAsync(request, self.id, self.token, messageJSON, {
				wait = true,
				threadId = threadId,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return message.new(self.state, response)
	end)
end

--[[
	get the followup response created by this interaction
]]
function Component.Prototype.getFollowupResponseAsync(self: Component, messageId: string, threadId: string?)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local status, response = rest.interaction
			.getFollowupMessageAsync(request, self.id, self.token, messageId, {
				threadId = threadId,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return message.new(self.state, response)
	end)
end

--[[
	edit the followup response created by this interaction
]]
function Component.Prototype.editFollowupResponseAsync(
	self: Component,
	messageId: apiTypes.Snowflake,
	messageJSON: builders.messageJSON,
	threadId: string?
)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local status, response = rest.interaction
			.editFollowupMessageAsync(request, self.id, self.token, messageId, messageJSON, {
				threadId = threadId,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return message.new(self.state, response)
	end)
end

--[[
	delete the followup response created by this interaction
]]
function Component.Prototype.deleteFollowupResponseAsync(self: Component, messageId: string): future.Future<string, nil>
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local status, response =
			rest.interaction.deleteFollowupMessageAsync(request, self.id, self.token, messageId):await()

		assert(status == "Fulfilled", tostring(response))
	end)
end

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
			isDeferred = false,
		} :: Component,
		{ __index = Component.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Component = typeof(Component.Prototype) & {
	isDeferred: boolean,
} & interactionBehaviour.Interaction

return Component.Interface
