--[[
	Implementation of discords MessageThread object as a Luau builder.	

	https://discord.com/developers/docs/resources/channel#start-thread-from-message-json-params
]]

local MessageThread = {}

MessageThread.Prototype = {}
MessageThread.Interface = {}

--[[
	Sets the name of the thread.
	Name must be between 1-100 characters.
]]
function MessageThread.Prototype.setName(self: MessageThread, name: string): MessageThread
	assert(#name <= 100, "Name must be less than 100 characters")
	assert(#name > 0, "Name must be greater than 0 characters")

	self.name = name

	return self
end

--[[
	Sets the duration in minutes before the thread is automatically archived.
	Duration must be 60, 1440, 4320, or 10080.
]]
function MessageThread.Prototype.setAutoArchiveDuration(self: MessageThread, duration: number): MessageThread
	assert(
		duration == 60 or duration == 1440 or duration == 4320 or duration == 10080,
		"Auto archive duration must be 60, 1440, 4320, or 10080"
	)

	self.autoArchiveDuration = duration

	return self
end

--[[
	Sets the rate limit per user in the thread.
	Rate limit must be less than or equal to 21600 seconds.
]]
function MessageThread.Prototype.setRateLimitPerUser(self: MessageThread, rateLimit: number): MessageThread
	assert(rateLimit <= 21600, "Rate limit must be less than or equal to 21600")

	self.rateLimitPerUser = rateLimit

	return self
end
--[[
	Responsible for building the MessageThread JSON that can be parsed by the Discord API.
]]
function MessageThread.Prototype.build(self: MessageThread): JSON
	assert(self.name, `Name must be set`)

	return {
		name = self.name,
		auto_archive_duration = self.autoArchiveDuration,
		rate_limit_per_user = self.rateLimitPerUser,
	}
end

--[[
	Responsible for creating a new MessageThread.

	```lua
	
	```
]]
function MessageThread.Interface.new(resource: {
	name: string?,
	autoArchiveDuration: number?,
	rateLimitPerUser: number?,
}?): MessageThread
	local self = setmetatable({} :: MessageThread, {
		__index = MessageThread.Prototype,
	})

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
