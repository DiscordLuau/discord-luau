--[=[
	@class Command
	Implementation of the Discord Command Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
	@__index Command.Prototype
]=]

-- selene: allow(unused_variable)
local state = require("../../../lune_packages/state")
local apiTypes = require("../../../lune_packages/api_types")

local interactionBehaviour = require("../behaviour/interaction")
local interactableBehaviour = require("../behaviour/interactable")

local user = require("../../user")

local Command = {}

Command.Interface = {}
Command.Prototype = {}
Command.Behaviours = {
	interactionBehaviour,
	interactableBehaviour,
}

--[=[
	@within Command
	Returns a list of users who have been mentioned in this interaction
]=]
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

--[=[
	@within Command
	Returns a list of members who have been mentioned in this interaction
]=]
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

--[=[
	@within Command
	Returns a list of roles which have been mentioned in this interaction
]=]
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

--[=[
	@within Command
	Returns a list of channels which have been mentioned in this interaction
]=]
function Command.Prototype.getChannels(_self: Command)
	error(`Unable to fetch channels! This is not yet implemented!`)
end

--[=[
	@within Command
	Returns a list of messages which have been mentioned in this interaction
]=]
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

--[=[
	@within Command
	Returns a list of attachments which have been mentioned in this interaction
]=]
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

--[=[
	@within Command
	@private

	Responsible for syncing data to this component interaction object. This is typically called by the API when this object is
	created or updated.
]=]
function Command.Prototype.sync(self: Command, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Command.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

--[=[
	@within Command
	@private

	Responsible for constructing this class.
]=]
function Command.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Command
	local self = setmetatable(
		{
			--[=[
				@prop state state.State
				@within Command
			]=]
			state = state,

			--[=[
				@prop isDeferred boolean
				@within Command
			]=]
			isDeferred = false,
		} :: Command,
		{ __index = Command.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Command = typeof(Command.Prototype) & {
	isDeferred: boolean,
} & interactionBehaviour.Interaction & interactableBehaviour.Interaction

return Command.Interface
