--[=[
	@class Builders.MessageThread
	@__index Prototype

	Implementation of discords MessageThread object as a Luau builder.	

	https://discord.com/developers/docs/resources/channel#start-thread-from-message-json-params
]=]

local MessageThread = {}

MessageThread.Prototype = {}
MessageThread.Interface = {}

--[=[
	@within Builders.MessageThread

	Sets the name of the thread.
	Name must be between 1-100 characters.
]=]
function MessageThread.Prototype.setName(self: MessageThread, name: string): MessageThread
	assert(#name <= 100, "Name must be less than 100 characters")
	assert(#name > 0, "Name must be greater than 0 characters")

	self.name = name

	return self
end

--[=[
	@within Builders.MessageThread

	Sets the duration in minutes before the thread is automatically archived.
	Duration must be 60, 1440, 4320, or 10080.
]=]
function MessageThread.Prototype.setAutoArchiveDuration(self: MessageThread, duration: number): MessageThread
	assert(
		duration == 60 or duration == 1440 or duration == 4320 or duration == 10080,
		"Auto archive duration must be 60, 1440, 4320, or 10080"
	)

	self.autoArchiveDuration = duration

	return self
end

--[=[
	@within Builders.MessageThread

	Sets the rate limit per user in the thread.
	Rate limit must be less than or equal to 21600 seconds.
]=]
function MessageThread.Prototype.setRateLimitPerUser(self: MessageThread, rateLimit: number): MessageThread
	assert(rateLimit <= 21600, "Rate limit must be less than or equal to 21600")

	self.rateLimitPerUser = rateLimit

	return self
end

--[=[
	@within Builders.MessageThread

	Responsible for building the MessageThread JSON that can be parsed by the Discord API.
]=]
function MessageThread.Prototype.build(self: MessageThread): JSON
	assert(self.name, `Name must be set`)

	return {
		name = self.name,
		auto_archive_duration = self.autoArchiveDuration,
		rate_limit_per_user = self.rateLimitPerUser,
	}
end

--[=[
	@within Builders.MessageThread

	Responsible for creating a new MessageThread.

	```luau
	local thread = MessageThread.new({
		name = "My Thread",
		autoArchiveDuration = 60,
		rateLimitPerUser = 0
	})
	```
]=]
function MessageThread.Interface.new(resource: {
	name: string?,
	autoArchiveDuration: number?,
	rateLimitPerUser: number?,
}?): MessageThread
	local self = setmetatable(
		{
			--[=[
				@prop name string?
				@within Builders.MessageThread
				The name of the thread that is displayed.
			]=]
			name = nil,

			--[=[
				@prop autoArchiveDuration number?
				@within Builders.MessageThread
				Duration in minutes to automatically archive the thread after recent activity.
			]=]
			autoArchiveDuration = nil,

			--[=[
				@prop rateLimitPerUser number?
				@within Builders.MessageThread
				Amount of seconds a user has to wait before sending another message.
			]=]
			rateLimitPerUser = nil,
		} :: MessageThread,
		{
			__index = MessageThread.Prototype,
		}
	)

	if resource then
		if resource.name then
			self:setName(resource.name)
		end

		if resource.autoArchiveDuration then
			self:setAutoArchiveDuration(resource.autoArchiveDuration)
		end

		if resource.rateLimitPerUser then
			self:setRateLimitPerUser(resource.rateLimitPerUser)
		end
	end

	return self
end

export type MessageThread = typeof(MessageThread.Prototype) & {
	name: string?,
	autoArchiveDuration: number?,
	rateLimitPerUser: number?,
}

export type JSON = typeof(MessageThread.Prototype.build(nil :: any))

return MessageThread.Interface
