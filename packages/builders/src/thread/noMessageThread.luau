--[=[
	@class Builders.NoMessageThread
	@__index Prototype

	Implementation of discords NoMessageThread object as a Luau builder.	

	https://discord.com/developers/docs/resources/channel#start-thread-without-message-json-params
]=]

local apiTypes = require("../../lune_packages/api_types")

local NoMessageThread = {}

NoMessageThread.Prototype = {}
NoMessageThread.Interface = {}

--[=[
	@within Builders.NoMessageThread

	Sets the name of the thread.
	Name must be between 1-100 characters.
]=]
function NoMessageThread.Prototype.setName(self: NoMessageThread, name: string): NoMessageThread
	assert(#name <= 100, "Name must be less than 100 characters")
	assert(#name > 0, "Name must be greater than 0 characters")

	self.name = name

	return self
end

--[=[
	@within Builders.NoMessageThread

	Sets the duration in minutes before the thread is automatically archived.
	Valid values are 60, 1440, 4320, or 10080.
]=]
function NoMessageThread.Prototype.setAutoArchiveDuration(self: NoMessageThread, duration: number): NoMessageThread
	assert(
		duration == 60 or duration == 1440 or duration == 4320 or duration == 10080,
		"Auto archive duration must be 60, 1440, 4320, or 10080"
	)

	self.autoArchiveDuration = duration

	return self
end

--[=[
	@within Builders.NoMessageThread

	Sets the type of thread channel.
	Must be a valid Discord channel type.
]=]
function NoMessageThread.Prototype.setType(self: NoMessageThread, type: apiTypes.ChannelType): NoMessageThread
	assert(apiTypes.channel.ChannelTypes[type], `Invalid channel type: {type}`)

	self.type = type

	return self
end

--[=[
	@within Builders.NoMessageThread

	Sets whether non-moderators can add other non-moderators to the thread.
]=]
function NoMessageThread.Prototype.setInvitable(self: NoMessageThread, invitable: boolean): NoMessageThread
	self.invitable = invitable

	return self
end

--[=[
	@within Builders.NoMessageThread

	Sets the amount of seconds a user has to wait before sending another message.
	Must be less than or equal to 21600 seconds (6 hours).
]=]
function NoMessageThread.Prototype.setRateLimitPerUser(self: NoMessageThread, rateLimit: number): NoMessageThread
	assert(rateLimit <= 21600, "Rate limit must be less than or equal to 21600")

	self.rateLimitPerUser = rateLimit

	return self
end

--[=[
	@within Builders.NoMessageThread

	Responsible for building the NoMessageThread JSON that can be parsed by the Discord API.
]=]
function NoMessageThread.Prototype.build(self: NoMessageThread): JSON
	assert(self.name, `Name must be set`)

	return {
		name = self.name,
		auto_archive_duration = self.autoArchiveDuration,
		type = apiTypes.channel.ChannelTypes[self.type],
		invitable = self.invitable,
		rate_limit_per_user = self.rateLimitPerUser,
	}
end

--[=[
	@within Builders.NoMessageThread

	Responsible for creating a new NoMessageThread.
]=]
function NoMessageThread.Interface.new(resource: {
	name: string?,
	autoArchiveDuration: number?,
	type: apiTypes.ChannelType?,
	invitable: boolean?,
	rateLimitPerUser: number?,
}?): NoMessageThread
	local self = setmetatable(
		{
			--[=[
				@prop name string?
				@within Builders.NoMessageThread
				The name of the thread that is displayed.
			]=]
			name = nil,

			--[=[
				@prop autoArchiveDuration number?
				@within Builders.NoMessageThread
				Duration in minutes to automatically archive the thread after recent activity.
			]=]
			autoArchiveDuration = nil,

			--[=[
				@prop type api_types.ChannelType?
				@within Builders.NoMessageThread
				The type of thread channel.
			]=]
			type = nil,

			--[=[
				@prop invitable boolean?
				@within Builders.NoMessageThread
				Whether non-moderators can add other non-moderators to the thread.
			]=]
			invitable = nil,

			--[=[
				@prop rateLimitPerUser number?
				@within Builders.NoMessageThread
				Amount of seconds a user has to wait before sending another message.
			]=]
			rateLimitPerUser = nil,
		} :: NoMessageThread,
		{
			__index = NoMessageThread.Prototype,
		}
	)

	if resource then
		if resource.name then
			self:setName(resource.name)
		end

		if resource.autoArchiveDuration then
			self:setAutoArchiveDuration(resource.autoArchiveDuration)
		end

		if resource.type then
			self:setType(resource.type)
		end

		if resource.invitable ~= nil then
			self:setInvitable(resource.invitable)
		end

		if resource.rateLimitPerUser then
			self:setRateLimitPerUser(resource.rateLimitPerUser)
		end
	end

	return self
end

export type NoMessageThread = typeof(NoMessageThread.Prototype) & {
	name: string?,
	autoArchiveDuration: number?,
	type: apiTypes.ChannelType?,
	invitable: boolean?,
	rateLimitPerUser: number?,
}

export type JSON = typeof(NoMessageThread.Prototype.build(nil :: any))

return NoMessageThread.Interface
