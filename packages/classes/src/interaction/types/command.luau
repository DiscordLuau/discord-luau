--[[
	Implementation of the Discord Command Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

-- selene: allow(unused_variable)
local state = require("../../../lune_packages/state")
local apiTypes = require("../../../lune_packages/api_types")
local future = require("../../../luau_packages/future")
local builders = require("../../../lune_packages/builders")
local rest = require("../../../lune_packages/rest")

local interactionBehaviour = require("../behaviour/interaction")
local message = require("../../message/message")
local user = require("../../user")

local Command = {}

Command.Interface = {}
Command.Prototype = {}
Command.Behaviours = {
	interactionBehaviour,
}

--[[
	acknowledge an interaction and edit a response later, the user sees a loading state
]]
function Command.Prototype.deferAsync(self: Command)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
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

--[[
	respond to this interaction with a message
]]
function Command.Prototype.messageAsync(self: Command, messageJSON: builders.messageJSON, responseMessage: boolean?)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
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

--[[
	get the response created by this interaction
]]
function Command.Prototype.getResponseAsync(self: Command, threadId: string?)
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

--[[
	edit the response made by this interaction
]]
function Command.Prototype.editResponseAsync(self: Command, messageJSON: builders.messageJSON, threadId: string?)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction
			.editOriginalInteractionResponseAsync(request, self.id, self.token, messageJSON, {
				threadId = threadId,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return message.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, message.Message>
end

--[[
	delete the original response made by this interaction
]]
function Command.Prototype.deleteResponseAsync(self: Command)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction.deleteOriginalInteractionResponseAsync(request, self.id, self.token):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	create a followup response to an interaction, followup responses are messages you can send after
	the initial response is sent.
]]
function Command.Prototype.createFollowupResponseAsync(
	self: Command,
	messageJSON: builders.messageJSON,
	threadId: string?
)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
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

--[[
	get the followup response created by this interaction
]]
function Command.Prototype.getFollowupResponseAsync(self: Command, messageId: string, threadId: string?)
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

--[[
	edit the followup response created by this interaction
]]
function Command.Prototype.editFollowupResponseAsync(
	self: Command,
	messageId: apiTypes.Snowflake,
	messageJSON: builders.messageJSON,
	threadId: string?
)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction
			.editFollowupMessageAsync(request, self.id, self.token, messageId, messageJSON, {
				threadId = threadId,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return message.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, message.Message>
end

--[[
	delete the followup response created by this interaction
]]
function Command.Prototype.deleteFollowupResponseAsync(self: Command, messageId: string)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction.deleteFollowupMessageAsync(request, self.id, self.token, messageId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Returns a list of users who have been mentioned in this interaction
]]
function Command.Prototype.getUsers(self: Command): { user.User }
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
function Command.Prototype.getMembers(self: Command)
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
function Command.Prototype.getRoles(self: Command)
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
function Command.Prototype.getChannels(_self: Command)
	error(`Unable to fetch channels! This is not yet implemented!`)
end

--[[
	Returns a list of messages which have been mentioned in this interaction
]]
function Command.Prototype.getMessages(self: Command)
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
function Command.Prototype.getAttachments(self: Command)
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

function Command.Prototype.sync(self: Command, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Command.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

function Command.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Command
	local self = setmetatable(
		{
			state = state,

			isDeferred = false,
		} :: Command,
		{ __index = Command.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Command = typeof(Command.Prototype) & {
	isDeferred: boolean,
} & interactionBehaviour.Interaction

return Command.Interface
