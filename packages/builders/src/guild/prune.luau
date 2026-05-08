--[=[
	@class Builders.GuildPrune
	@__index Prototype

	Implementation of Discord's Begin Guild Prune params as a Luau builder.

	https://discord.com/developers/docs/resources/guild#begin-guild-prune-json-params
]=]

local GuildPrune = {}

GuildPrune.Prototype = {}
GuildPrune.Interface = {}

function GuildPrune.Prototype.setDays(self: GuildPrune, days: number): GuildPrune
	assert(days >= 1 and days <= 30, "days must be between 1 and 30")
	self.days = days
	return self
end

function GuildPrune.Prototype.setComputePruneCount(self: GuildPrune, compute: boolean): GuildPrune
	self.computePruneCount = compute
	return self
end

function GuildPrune.Prototype.setIncludeRoles(self: GuildPrune, roles: { string }): GuildPrune
	self.includeRoles = roles
	return self
end

function GuildPrune.Prototype.build(self: GuildPrune): JSON
	return {
		days = self.days,
		compute_prune_count = self.computePruneCount,
		include_roles = self.includeRoles,
	}
end

function GuildPrune.Interface.new(resource: {
	days: number?,
	computePruneCount: boolean?,
	includeRoles: { string }?,
}?): GuildPrune
	local self = setmetatable({} :: GuildPrune, { __index = GuildPrune.Prototype })

	if resource then
		if resource.days then
			self:setDays(resource.days)
		end
		if resource.computePruneCount ~= nil then
			self:setComputePruneCount(resource.computePruneCount)
		end
		if resource.includeRoles then
			self:setIncludeRoles(resource.includeRoles)
		end
	end

	return self
end

export type GuildPrune = typeof(GuildPrune.Prototype) & {
	days: number?,
	computePruneCount: boolean?,
	includeRoles: { string }?,
}

export type JSON = typeof(GuildPrune.Prototype.build(nil :: any))

return GuildPrune.Interface
