--[=[
	@class Classes.Interactions.Command
	@tag inherit:Classes.Interactions.InteractionBehaviour
	@tag inherit:Classes.Interactions.Interactable
	Implementation of the Discord Command Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
	@__index Command.Prototype
]=]

--[=[
	@prop state state.State
	@within Classes.Interactions.Command
]=]

--[=[
	@prop isDeferred boolean
	@within Classes.Interactions.Command
]=]

-- selene: allow(unused_variable)
local state = require("../../../luau_packages/state")
local apiTypes = require("../../../luau_packages/api_types")

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
	@within Classes.Interactions.Command
	Returns a list of users who have been mentioned in this interaction
]=]
function Command.Prototype.getUsers(self: Command): { user.User }
	if self.data and self.data.resolved and self.data.resolved.users then
		local userArray = {}

		for _, user in self.data.resolved.users do
			table.insert(userArray, user)
		end

		return userArray :: any
	else
		return {}
	end
end

--[=[
	@within Classes.Interactions.Command
	Returns a list of members who have been mentioned in this interaction
]=]
function Command.Prototype.getMembers(self: Command)
	if self.data and self.data.resolved and self.data.resolved.members then
		local memberArray = {}

		for _, member in self.data.resolved.members do
			table.insert(memberArray, member)
		end

		return memberArray
	else
		return {}
	end
end

--[=[
	@within Classes.Interactions.Command
	Returns a list of roles which have been mentioned in this interaction
]=]
function Command.Prototype.getRoles(self: Command)
	if self.data and self.data.resolved and self.data.resolved.roles then
		local roleArray = {}

		for _, role in self.data.resolved.roles do
			table.insert(roleArray, role)
		end

		return roleArray
	else
		return {}
	end
end

--[=[
	@within Classes.Interactions.Command
	Returns a list of channels which have been mentioned in this interaction
]=]
function Command.Prototype.getChannels(self: Command)
	if self.data and self.data.resolved and self.data.resolved.channels then
		local channelArray = {}

		for _, channel in self.data.resolved.channels do
			table.insert(channelArray, channel)
		end

		return channelArray
	else
		return {}
	end
end

--[=[
	@within Classes.Interactions.Command
	Returns a list of messages which have been mentioned in this interaction
]=]
function Command.Prototype.getMessages(self: Command)
	if self.data and self.data.resolved and self.data.resolved.messages then
		local messageArray = {}

		for _, message in self.data.resolved.messages do
			table.insert(messageArray, message)
		end

		return messageArray
	else
		return {}
	end
end

--[=[
	@within Classes.Interactions.Command
	Returns a list of attachments which have been mentioned in this interaction
]=]
function Command.Prototype.getAttachments(self: Command)
	if self.data and self.data.resolved and self.data.resolved.attachments then
		local attachmentArray = {}

		for _, attachment in self.data.resolved.attachments do
			table.insert(attachmentArray, attachment)
		end

		return attachmentArray
	else
		return {}
	end
end

--[=[
	@within Classes.Interactions.Command
	Returns the option with the given name, or nil if not found. Searches top-level options only.
]=]
function Command.Prototype.getOption(self: Command, name: string)
	if not self.data then
		return nil
	end

	for _, option in self.data.options do
		if option.name == name then
			return option
		end
	end

	return nil
end

--[=[
	@within Classes.Interactions.Command

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
	@within Classes.Interactions.Command

	Responsible for constructing this class.
]=]
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
} & interactionBehaviour.Interaction & interactableBehaviour.Interaction

return Command.Interface
