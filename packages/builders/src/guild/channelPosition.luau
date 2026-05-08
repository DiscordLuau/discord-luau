--[=[
	@class Builders.ChannelPosition
	@__index Prototype

	Implementation of Discord's Modify Guild Channel Positions params as a Luau builder.

	https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions-json-params
]=]

local ChannelPosition = {}

ChannelPosition.Prototype = {}
ChannelPosition.Interface = {}

function ChannelPosition.Prototype.setId(self: ChannelPosition, channelId: string): ChannelPosition
	self.id = channelId
	return self
end

function ChannelPosition.Prototype.setPosition(self: ChannelPosition, position: number?): ChannelPosition
	self.position = position
	return self
end

function ChannelPosition.Prototype.setLockPermissions(self: ChannelPosition, lock: boolean?): ChannelPosition
	self.lockPermissions = lock
	return self
end

function ChannelPosition.Prototype.setParentId(self: ChannelPosition, parentId: string?): ChannelPosition
	self.parentId = parentId
	return self
end

function ChannelPosition.Prototype.build(self: ChannelPosition): JSON
	assert(self.id, "Channel position is missing an id")

	return {
		id = self.id,
		position = self.position,
		lock_permissions = self.lockPermissions,
		parent_id = self.parentId,
	}
end

function ChannelPosition.Interface.new(resource: {
	id: string?,
	position: number?,
	lockPermissions: boolean?,
	parentId: string?,
}?): ChannelPosition
	local self = setmetatable({} :: ChannelPosition, { __index = ChannelPosition.Prototype })

	if resource then
		if resource.id then
			self:setId(resource.id)
		end
		if resource.position ~= nil then
			self:setPosition(resource.position)
		end
		if resource.lockPermissions ~= nil then
			self:setLockPermissions(resource.lockPermissions)
		end
		if resource.parentId ~= nil then
			self:setParentId(resource.parentId)
		end
	end

	return self
end

export type ChannelPosition = typeof(ChannelPosition.Prototype) & {
	id: string?,
	position: number?,
	lockPermissions: boolean?,
	parentId: string?,
}

export type JSON = typeof(ChannelPosition.Prototype.build(nil :: any))

return ChannelPosition.Interface
