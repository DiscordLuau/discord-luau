--[[
	Implementation of the Discord Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

local future = require("@vendor/future")

local apiTypes = require("@api-types/apiTypes")

local messageBuilder = require("@builders/message/message")
local interactionBehaviour = require("@classes/interaction/behaviour/interaction")
local message = require("@classes/message/message")
local user = require("@classes/user")

-- selene: allow(unused_variable)
local state = require("@classes/state")

local interactionRest = require("@rest/interaction")

local Interaction = {}

Interaction.Interface = {}
Interaction.Prototype = {}
Interaction.Behaviours = {
	interactionBehaviour,
}

--[[
	acknowledge an interaction and edit a response later, the user sees a loading state
]]
function Interaction.Prototype.deferAsync(self: Interaction): future.Future<nil>
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response = interactionRest
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = 5,
				data = {},
			})
			:await()

		self.isDeferred = true

		assert(status == "Fulfilled", tostring(response))
	end)
end

--[[
	acknowledge an interaction ping
]]
function Interaction.Prototype.pongAsync(self: Interaction): future.Future<nil>
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response = interactionRest
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = 1,
				data = {},
			})
			:await()

		assert(status == "Fulfilled", tostring(response))
	end)
end

--[[
	respond to this interaction with a message
]]
function Interaction.Prototype.messageAsync(self: Interaction, messageJSON: messageBuilder.JSON)
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response = interactionRest
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = self.isDeferred and 4 or 5,
				data = messageJSON,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return message.new(self.state, response)
	end)
end

--[[
	get the response created by this interaction
]]
function Interaction.Prototype.getResponseAsync(self: Interaction, threadId: string?): future.Future<message.Message>
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
function Interaction.Prototype.editResponseAsync(
	self: Interaction,
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
function Interaction.Prototype.deleteResponseAsync(self: Interaction): future.Future<nil>
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
function Interaction.Prototype.createFollowupResponseAsync(
	self: Interaction,
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
function Interaction.Prototype.getFollowupResponseAsync(self: Interaction, messageId: string, threadId: string?)
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
function Interaction.Prototype.editFollowupResponseAsync(
	self: Interaction,
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
function Interaction.Prototype.deleteFollowupResponseAsync(self: Interaction, messageId: string): future.Future<nil>
	local request = self.state.rest:newRequest()

	return future.new(function()
		local status, response =
			interactionRest.deleteFollowupMessageAsync(request, self.id, self.token, messageId):await()

		assert(status == "Fulfilled", tostring(response))
	end)
end

--[[
	Returns a list of users who have been mentioned in this interaction
]]
function Interaction.Prototype.getUsers(self: Interaction): { user.User }
	if self.data and self.data.resolved and self.data.resolved.users then
		local userArray = {}

		for _, user in self.data.resolved.users do
			table.insert(userArray, user)
		end

		return userArray
	else
		return {}
	end
end

--[[
	Returns a list of members who have been mentioned in this interaction
]]
function Interaction.Prototype.getMembers(self: Interaction)
	if self.data and self.data.resolved and self.data.resolved.members then
		local memberArray = {}

		for _, user in self.data.resolved.members do
			table.insert(memberArray, user)
		end

		return memberArray
	else
		return {}
	end
end

--[[
	Returns a list of roles which have been mentioned in this interaction
]]
function Interaction.Prototype.getRoles(self: Interaction)
	if self.data and self.data.resolved and self.data.resolved.roles then
		local roleArray = {}

		for _, user in self.data.resolved.roles do
			table.insert(roleArray, user)
		end

		return roleArray
	else
		return {}
	end
end

--[[
	Returns a list of channels which have been mentioned in this interaction
]]
function Interaction.Prototype.getChannels(_self: Interaction)
	error(`Unable to fetch channels! This is not yet implemented!`)
end

--[[
	Returns a list of messages which have been mentioned in this interaction
]]
function Interaction.Prototype.getMessages(self: Interaction)
	if self.data and self.data.resolved and self.data.resolved.messages then
		local messageArray = {}

		for _, user in self.data.resolved.messages do
			table.insert(messageArray, user)
		end

		return messageArray
	else
		return {}
	end
end

--[[
	Returns a list of attachments which have been mentioned in this interaction
]]
function Interaction.Prototype.getAttachments(self: Interaction)
	if self.data and self.data.resolved and self.data.resolved.attachments then
		local attachmentArray = {}

		for _, user in self.data.resolved.attachments do
			table.insert(attachmentArray, user)
		end

		return attachmentArray
	else
		return {}
	end
end

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

			isDeferred = false,
		} :: Interaction,
		{ __index = Interaction.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Interaction = typeof(Interaction.Prototype) & {
	isDeferred: boolean,
} & interactionBehaviour.Interaction

return Interaction.Interface
