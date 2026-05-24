--[=[
	@class Builders.GuildMember
	@__index Prototype

	Implementation of Discord's Modify Guild Member params as a Luau builder.

	https://discord.com/developers/docs/resources/guild#modify-guild-member-json-params
]=]

local GuildMember = {}

GuildMember.Prototype = {}
GuildMember.Interface = {}

function GuildMember.Prototype.setNick(self: GuildMember, nick: string?): GuildMember
	self.nick = nick
	return self
end

function GuildMember.Prototype.setRoles(self: GuildMember, roles: { string }): GuildMember
	self.roles = roles
	return self
end

function GuildMember.Prototype.setMute(self: GuildMember, mute: boolean): GuildMember
	self.mute = mute
	return self
end

function GuildMember.Prototype.setDeaf(self: GuildMember, deaf: boolean): GuildMember
	self.deaf = deaf
	return self
end

function GuildMember.Prototype.setChannelId(self: GuildMember, channelId: string?): GuildMember
	self.channelId = channelId
	return self
end

function GuildMember.Prototype.setCommunicationDisabledUntil(self: GuildMember, isoTimestamp: string?): GuildMember
	self.communicationDisabledUntil = isoTimestamp
	return self
end

function GuildMember.Prototype.setFlags(self: GuildMember, flags: number): GuildMember
	self.flags = flags
	return self
end

function GuildMember.Prototype.build(self: GuildMember): JSON
	return {
		nick = self.nick,
		roles = self.roles,
		mute = self.mute,
		deaf = self.deaf,
		channel_id = self.channelId,
		communication_disabled_until = self.communicationDisabledUntil,
		flags = self.flags,
	}
end

function GuildMember.Interface.new(resource: {
	nick: string?,
	roles: { string }?,
	mute: boolean?,
	deaf: boolean?,
	channelId: string?,
	communicationDisabledUntil: string?,
	flags: number?,
}?): GuildMember
	local self = setmetatable({} :: GuildMember, { __index = GuildMember.Prototype })

	if resource then
		if resource.nick ~= nil then
			self:setNick(resource.nick)
		end
		if resource.roles then
			self:setRoles(resource.roles)
		end
		if resource.mute ~= nil then
			self:setMute(resource.mute)
		end
		if resource.deaf ~= nil then
			self:setDeaf(resource.deaf)
		end
		if resource.channelId ~= nil then
			self:setChannelId(resource.channelId)
		end
		if resource.communicationDisabledUntil ~= nil then
			self:setCommunicationDisabledUntil(resource.communicationDisabledUntil)
		end
		if resource.flags then
			self:setFlags(resource.flags)
		end
	end

	return self
end

export type GuildMember = typeof(GuildMember.Prototype) & {
	nick: string?,
	roles: { string }?,
	mute: boolean?,
	deaf: boolean?,
	channelId: string?,
	communicationDisabledUntil: string?,
	flags: number?,
}

export type JSON = typeof(GuildMember.Prototype.build(nil :: any))

return GuildMember.Interface
