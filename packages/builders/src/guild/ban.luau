--[=[
	@class Builders.GuildBan
	@__index Prototype

	Implementation of Discord's Create Guild Ban params as a Luau builder.

	https://discord.com/developers/docs/resources/guild#create-guild-ban-json-params
]=]

local GuildBan = {}

GuildBan.Prototype = {}
GuildBan.Interface = {}

function GuildBan.Prototype.setDeleteMessageSeconds(self: GuildBan, seconds: number): GuildBan
	assert(seconds >= 0 and seconds <= 604800, "delete_message_seconds must be between 0 and 604800")
	self.deleteMessageSeconds = seconds
	return self
end

function GuildBan.Prototype.build(self: GuildBan): JSON
	return {
		delete_message_seconds = self.deleteMessageSeconds,
	}
end

function GuildBan.Interface.new(resource: {
	deleteMessageSeconds: number?,
}?): GuildBan
	local self = setmetatable({} :: GuildBan, { __index = GuildBan.Prototype })

	if resource then
		if resource.deleteMessageSeconds then
			self:setDeleteMessageSeconds(resource.deleteMessageSeconds)
		end
	end

	return self
end

export type GuildBan = typeof(GuildBan.Prototype) & {
	deleteMessageSeconds: number?,
}

export type JSON = typeof(GuildBan.Prototype.build(nil :: any))

return GuildBan.Interface
