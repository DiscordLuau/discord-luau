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
local guildMember = require("../../guild/member")
local role = require("../../guild/role")
local attachment = require("../../attachment")

local function getActiveOptions(data: any): { any }
	if data == nil then
		return {}
	end
	local options = data.options
	if options == nil or #options == 0 then
		return {}
	end
	local first = options[1]
	local firstType = (first.type :: any) :: string
	if firstType == "SubCommand" then
		return (first.options :: any) or {}
	elseif firstType == "SubCommandGroup" then
		local nested = first.options :: any
		if nested and #nested > 0 then
			return (nested[1].options :: any) or {}
		end
	end
	return options
end

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
	Returns the raw option object for `name`, descending into the active subcommand or
	subcommand-group if present. Returns nil when the option is absent or data is missing.
]=]
function Command.Prototype.getOption(self: Command, name: string)
	if not self.data then
		return nil
	end

	for _, option in getActiveOptions(self.data) do
		if option.name == name then
			return option
		end
	end

	return nil
end

--[=[
	@within Classes.Interactions.Command
	Returns the string value of the named option, or nil if absent.
]=]
function Command.Prototype.getString(self: Command, name: string): string?
	local opt: any = self:getOption(name)
	return if opt ~= nil and opt.value ~= nil then opt.value :: string else nil
end

--[=[
	@within Classes.Interactions.Command
	Returns the integer value of the named option, or nil if absent.
]=]
function Command.Prototype.getInteger(self: Command, name: string): number?
	local opt: any = self:getOption(name)
	return if opt ~= nil and opt.value ~= nil then opt.value :: number else nil
end

--[=[
	@within Classes.Interactions.Command
	Returns the number (float) value of the named option, or nil if absent.
]=]
function Command.Prototype.getNumber(self: Command, name: string): number?
	local opt: any = self:getOption(name)
	return if opt ~= nil and opt.value ~= nil then opt.value :: number else nil
end

--[=[
	@within Classes.Interactions.Command
	Returns the boolean value of the named option, or nil if absent.
]=]
function Command.Prototype.getBoolean(self: Command, name: string): boolean?
	local opt: any = self:getOption(name)
	return if opt ~= nil and opt.value ~= nil then opt.value :: boolean else nil
end

--[=[
	@within Classes.Interactions.Command
	Returns the resolved User for the named option, or nil if absent.
]=]
function Command.Prototype.getUser(self: Command, name: string): user.User?
	local opt: any = self:getOption(name)
	if opt == nil or not self.data or not self.data.resolved then
		return nil
	end
	return (self.data.resolved.users :: any)[opt.value :: string]
end

--[=[
	@within Classes.Interactions.Command
	Returns the resolved GuildMember for the named option, or nil if absent.
	Only populated in guild interactions.
]=]
function Command.Prototype.getMember(self: Command, name: string): guildMember.Member?
	local opt: any = self:getOption(name)
	if opt == nil or not self.data or not self.data.resolved then
		return nil
	end
	return (self.data.resolved.members :: any)[opt.value :: string]
end

--[=[
	@within Classes.Interactions.Command
	Returns the resolved Role for the named option, or nil if absent.
]=]
function Command.Prototype.getRole(self: Command, name: string): role.Role?
	local opt: any = self:getOption(name)
	if opt == nil or not self.data or not self.data.resolved then
		return nil
	end
	return (self.data.resolved.roles :: any)[opt.value :: string]
end

--[=[
	@within Classes.Interactions.Command
	Returns the partial channel for the named option, or nil if absent.
	Channels in resolved data are partial - id, name, type, and permissions only.
]=]
function Command.Prototype.getChannel(self: Command, name: string): apiTypes.AbstractChannel?
	local opt: any = self:getOption(name)
	if opt == nil or not self.data or not self.data.resolved then
		return nil
	end
	return (self.data.resolved.channels :: any)[opt.value :: string]
end

--[=[
	@within Classes.Interactions.Command
	Returns the resolved Attachment for the named option, or nil if absent.
]=]
function Command.Prototype.getAttachment(self: Command, name: string): attachment.Attachment?
	local opt: any = self:getOption(name)
	if opt == nil or not self.data or not self.data.resolved then
		return nil
	end
	return (self.data.resolved.attachments :: any)[opt.value :: string]
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
