--[=[
	@class Classes.Resolved
	@__index Prototype

	Implementation of the Discord Resolved class in Luau

	https://discord.com/developers/docs/resources/message#attachment-object
]=]

local apiTypes = require("../lune_packages/api_types")

local state = require("../lune_packages/state")

local user = require("./user")
local member = require("./guild/member")
local role = require("./guild/role")
local attachment = require("./attachment")
local message = require("./message/message")

local constructChannelFromData = require("./channels/construct")

local Resolved = {}

Resolved.Interface = {}
Resolved.Prototype = {}

--[=[
	@within Classes.Resolved
	@private

	Responsible for syncing data to this resolved object. This is typically called by the API when this object is
	created or updated.
]=]
function Resolved.Prototype.sync(self: Resolved, resolvedData: apiTypes.ResolvedDataStructure)
	--[=[
		@prop users { [string]: Classes.User }
		@within Classes.Resolved
		A dictionary of user objects, keyed by user ID
	]=]
	for id, userData in next, resolvedData.users or {} do
		self.users[id] = user.new(userData)
	end

	--[=[
		@prop members { [string]: Classes.Member }
		@within Classes.Resolved
		A dictionary of guild member objects, keyed by user ID
	]=]
	for id, memberData in next, resolvedData.members or {} do
		self.members[id] = member.new(self.state, "_interaction", memberData)
	end

	--[=[
		@prop roles { [string]: Classes.Role }
		@within Classes.Resolved
		A dictionary of role objects, keyed by role ID
	]=]
	for id, roleData in next, resolvedData.roles or {} do
		self.roles[id] = role.new(self.state, "_interaction", roleData)
	end

	--[=[
		@prop channels { [string]: api_types.AbstractChannel }
		@within Classes.Resolved
		A dictionary of channel objects, keyed by channel ID
	]=]
	for id, channelData in next, resolvedData.channels or {} do
		self.channels[id] = constructChannelFromData(self.state, channelData) :: apiTypes.AbstractChannel
	end

	--[=[
		@prop messages { [string]: Classes.Message }
		@within Classes.Resolved
		A dictionary of message objects, keyed by message ID
	]=]
	for id, messageData in next, resolvedData.messages or {} do
		self.messages[id] = message.new(self.state, messageData)
	end

	--[=[
		@prop attachments { [string]: Classes.Attachment }
		@within Classes.Resolved
		A dictionary of attachment objects, keyed by attachment ID
	]=]
	for id, attachmentData in next, resolvedData.attachments or {} do
		self.attachments[id] = attachment.new(attachmentData)
	end
end

--[=[
	@within Classes.Resolved
	@private

	Responsible for constructing this class.
]=]
function Resolved.Interface.new(state: state.State, resolvedData: apiTypes.ResolvedDataStructure): Resolved
	local self = setmetatable(
		{
			state = state,

			users = {},
			members = {},
			roles = {},
			channels = {},
			messages = {},
			attachments = {},
		} :: Resolved,
		{ __index = Resolved.Prototype }
	)

	self:sync(resolvedData)

	return self
end

export type Resolved = typeof(Resolved.Prototype) & {
	state: state.State,

	users: { [apiTypes.Snowflake]: user.User },
	members: { [apiTypes.Snowflake]: member.Member },
	roles: { [apiTypes.Snowflake]: role.Role },
	channels: { [apiTypes.Snowflake]: apiTypes.AbstractChannel },
	messages: { [apiTypes.Snowflake]: message.Message },
	attachments: { [apiTypes.Snowflake]: attachment.Attachment },
}

return Resolved.Interface
