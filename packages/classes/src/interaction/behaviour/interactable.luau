--[=[
	@class Classes.Interactable
	@__index Interaction.Prototype
	
	Interactable interaction behaviours for Discord interactions.
]=]

--[=[
	@within Classes.Interactable
	@prop state State
	The state object for this interaction.
]=]

--[=[
	@within Classes.Interactable
	@prop id string
	The ID of the interaction.
]=]

--[=[
	@within Classes.Interactable
	@prop token string
	The token for this interaction.
]=]

--[=[
	@within Classes.Interactable
	@prop isDeferred boolean
	Whether this interaction has been deferred.
]=]

local state = require("../../../lune_packages/state")
local apiTypes = require("../../../lune_packages/api_types")
local future = require("../../../luau_packages/future")
local builders = require("../../../lune_packages/builders")
local rest = require("../../../lune_packages/rest")

local message = require("../../message/message")

local Interaction = {}

Interaction.Interface = {}
Interaction.Prototype = {}

--[=[
	@within Classes.Interactable
	Acknowledge an interaction and edit a response later, the user sees a loading state.
]=]
function Interaction.Prototype.deferAsync(self: Interaction)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.interaction
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = 5,
				data = {},
			}, {
				withResponse = false,
			})
			:await()

		self.isDeferred = true

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Interactable
	Respond to this interaction with a message.
]=]
function Interaction.Prototype.messageAsync(
	self: Interaction,
	messageJSON: builders.messageJSON,
	responseMessage: boolean?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		request:setFlag("FormdataRequest", true)

		local response = rest.interaction
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = self.isDeferred and 5 or 4,
				data = messageJSON,
			}, {
				withResponse = responseMessage or false,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local data = response:unwrapOk()

		if responseMessage and data.resource.message then
			return message.new(self.state, data.resource.message) :: any
		else
			return nil :: any
		end
	end) :: future.FutureLike<string, message.Message?>
end

--[=[
	@within Classes.Interactable
	Respond to this interaction with a modal.
]=]
function Interaction.Prototype.modalAsync(self: Interaction, modalJSON: builders.ModalJSON, responseMessage: boolean?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.interaction
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = 9,
				data = modalJSON,
			}, {
				withResponse = responseMessage or false,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local data = response:unwrapOk()

		if responseMessage and data.resource and data.resource.message then
			return message.new(self.state, data.resource.message) :: any
		else
			return nil :: any
		end
	end) :: future.FutureLike<string, message.Message?>
end

--[=[
	@within Classes.Interactable
	Get the response created by this interaction.
]=]
function Interaction.Prototype.getResponseAsync(self: Interaction, threadId: string?)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction
			.getOriginalInteractionResponseAsync(request, self.id, self.token, {
				threadId = threadId,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return message.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, message.Message>
end

--[=[
	@within Classes.Interactable
	Edit the response made by this interaction.
]=]
function Interaction.Prototype.editResponseAsync(
	self: Interaction,
	messageJSON: builders.messageJSON,
	threadId: string?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		request:setFlag("FormdataRequest", true)

		local response = rest.interaction
			.editOriginalInteractionResponseAsync(request, self.id, self.token, messageJSON, {
				threadId = threadId,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return message.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, message.Message>
end

--[=[
	@within Classes.Interactable
	Delete the original response made by this interaction.
]=]
function Interaction.Prototype.deleteResponseAsync(self: Interaction)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction.deleteOriginalInteractionResponseAsync(request, self.id, self.token):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Interactable
	Create a followup response to an interaction, followup responses are messages you can send after
	the initial response is sent.
]=]
function Interaction.Prototype.createFollowupResponseAsync(
	self: Interaction,
	messageJSON: builders.messageJSON,
	threadId: string?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		request:setFlag("FormdataRequest", true)

		local response = rest.interaction
			.createFollowupMessageAsync(request, self.id, self.token, messageJSON, {
				wait = true,
				threadId = threadId,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return message.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, message.Message>
end

--[=[
	@within Classes.Interactable
	Get the followup response created by this interaction.
]=]
function Interaction.Prototype.getFollowupResponseAsync(self: Interaction, messageId: string, threadId: string?)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction
			.getFollowupMessageAsync(request, self.id, self.token, messageId, {
				threadId = threadId,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return message.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, message.Message>
end

--[=[
	@within Classes.Interactable
	Edit the followup response created by this interaction.
]=]
function Interaction.Prototype.editFollowupResponseAsync(
	self: Interaction,
	messageId: apiTypes.Snowflake,
	messageJSON: builders.messageJSON,
	threadId: string?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		request:setFlag("FormdataRequest", true)

		local response = rest.interaction
			.editFollowupMessageAsync(request, self.id, self.token, messageId, messageJSON, {
				threadId = threadId,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return message.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, message.Message>
end

--[=[
	@within Classes.Interactable
	Delete the followup response created by this interaction.
]=]
function Interaction.Prototype.deleteFollowupResponseAsync(self: Interaction, messageId: string)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction.deleteFollowupMessageAsync(request, self.id, self.token, messageId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Interactable
	@private
	Inherit properties from the Interaction class.
]=]
function Interaction.Interface.inheritProperties() end

--[=[
	@within Classes.Interactable
	@private
	Inherit methods from the Interaction class.
]=]
function Interaction.Interface.inheritMethods(class: any)
	for key, value in Interaction.Prototype do
		class[key] = value
	end
end

export type InteractionMethods = typeof(Interaction.Prototype)

export type Interaction = InteractionMethods & {
	state: state.State,
	id: string,
	token: string,
	isDeferred: boolean?,
}

return Interaction.Interface
