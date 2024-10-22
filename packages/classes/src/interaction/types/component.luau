--[[
	Implementation of the Discord Component Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

local future = require("@vendor/future")

local apiTypes = require("@api-types/apiTypes")

local interactionRest = require("@rest/interaction")

local messageBuilder = require("@builders/message/message")
local interactionBehaviour = require("@classes/interaction/behaviour/interaction")
local message = require("@classes/message/message")

-- selene: allow(unused_variable)
local state = require("@classes/state")

local Component = {}

Component.Interface = {}
Component.Prototype = {}
Component.Behaviours = {
	interactionBehaviour,
}

--[[
	acknowledge an interaction and edit a response later, the user sees a loading state
]]
function Component.Prototype.deferAsync(self: Component): future.Future<nil>
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response = interactionRest
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
	messageJSON: messageBuilder.JSON,
	responseMessage: boolean?
): future.Future<message.Message?>
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response = interactionRest
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
function Component.Prototype.getResponseAsync(self: Component, threadId: string?): future.Future<message.Message>
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response = interactionRest
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
	messageJSON: messageBuilder.JSON,
	threadId: string?
): future.Future<message.Message>
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response = interactionRest
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
function Component.Prototype.deleteResponseAsync(self: Component): future.Future<nil>
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response =
			interactionRest.deleteOriginalInteractionResponseAsync(request, self.id, self.token):await()

		assert(status == "Fulfilled", tostring(response))
	end)
end

--[[
	create a followup response to an interaction, followup responses are messages you can send after
	the initial response is sent.
]]
function Component.Prototype.createFollowupResponseAsync(
	self: Component,
	messageJSON: messageBuilder.JSON,
	threadId: string?
)
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response = interactionRest
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

	return future.new(function()
		local status, response = interactionRest
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
	messageJSON: messageBuilder.JSON,
	threadId: string?
)
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response = interactionRest
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
function Component.Prototype.deleteFollowupResponseAsync(self: Component, messageId: string): future.Future<nil>
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response =
			interactionRest.deleteFollowupMessageAsync(request, self.id, self.token, messageId):await()

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
