--[[
	Implementation of the Discord Resolved class in Luau

	https://discord.com/developers/docs/resources/message#attachment-object
]]

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

function Resolved.Prototype.sync(self: Resolved, resolvedData: apiTypes.ResolvedDataStructure)
	for id, userData in next, resolvedData.users or {} do
		self.users[id] = user.new(userData)
	end

	for id, memberData in next, resolvedData.members or {} do
		self.members[id] = member.new(self.state, "_interaction", memberData)
	end

	for id, roleData in next, resolvedData.roles or {} do
		self.roles[id] = role.new(self.state, "_interaction", roleData)
	end

	for id, channelData in next, resolvedData.channels or {} do
		self.channels[id] = constructChannelFromData(self.state, channelData) :: apiTypes.AbstractChannel
	end

	for id, messageData in next, resolvedData.messages or {} do
		self.messages[id] = message.new(self.state, messageData)
	end

	for id, attachmentData in next, resolvedData.attachments or {} do
		self.attachments[id] = attachment.new(attachmentData)
	end
end

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
