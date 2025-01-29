--[[
	Implementation of discords ForumMediaThread object as a Luau builder.	

	https://discord.com/developers/docs/resources/channel#start-thread-without-message-json-params
]]

local messageParams = require("./messageParams")

local ForumMediaThread = {}

ForumMediaThread.Prototype = {}
ForumMediaThread.Interface = {}

--[[
	Sets the name of the forum thread.
	Name must be between 1-100 characters.
]]
function ForumMediaThread.Prototype.setName(self: ForumMediaThread, name: string): ForumMediaThread
	assert(#name <= 100, "Name must be less than 100 characters")
	assert(#name > 0, "Name must be greater than 0 characters")

	self.name = name

	return self
end

--[[
	Sets the duration after which the thread will automatically archive.
	Duration must be one of: 60, 1440, 4320, or 10080 minutes.
]]
function ForumMediaThread.Prototype.setAutoArchiveDuration(self: ForumMediaThread, duration: number): ForumMediaThread
	assert(
		duration == 60 or duration == 1440 or duration == 4320 or duration == 10080,
		"Auto archive duration must be 60, 1440, 4320, or 10080"
	)

	self.autoArchiveDuration = duration

	return self
end

--[[
	Sets the rate limit per user for the thread in seconds.
	Rate limit must not exceed 21600 seconds (6 hours).
]]
function ForumMediaThread.Prototype.setRateLimitPerUser(self: ForumMediaThread, rateLimit: number): ForumMediaThread
	assert(rateLimit <= 21600, "Rate limit must be less than or equal to 21600")

	self.rateLimitPerUser = rateLimit

	return self
end

--[[
	Adds a tag to the forum thread.
	Tags can be used to categorize or filter threads.
]]
function ForumMediaThread.Prototype.addTag(self: ForumMediaThread, rateLimit: string): ForumMediaThread
	table.insert(self.appliedTags, rateLimit)

	return self
end

--[[
	Sets the initial message content for the forum thread.
	The message must be a valid message parameters object.
]]
function ForumMediaThread.Prototype.setMessage(self: ForumMediaThread, message: messageParams.JSON): ForumMediaThread
	self.message = message

	return self
end

--[[
	Responsible for building the ForumMediaThread JSON that can be parsed by the Discord API.
]]
function ForumMediaThread.Prototype.build(self: ForumMediaThread): JSON
	assert(self.name, `Name must be set`)
	assert(self.message, `Message must be set`)

	return {
		name = self.name,
		auto_archive_duration = self.autoArchiveDuration,
		rate_limit_per_user = self.rateLimitPerUser,
		message = self.message,
		applied_tags = self.appliedTags :: { string }?,
	}
end

--[[
	Responsible for creating a new ForumMediaThread.

	```lua
	
	```
]]
function ForumMediaThread.Interface.new(resource: {
	name: string?,
	autoArchiveDuration: number?,
	rateLimitPerUser: number?,
}?): ForumMediaThread
	local self = setmetatable(
		{
			appliedTags = {},
		} :: ForumMediaThread,
		{
			__index = ForumMediaThread.Prototype,
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

export type ForumMediaThread = typeof(ForumMediaThread.Prototype) & {
	name: string?,
	autoArchiveDuration: number?,
	rateLimitPerUser: number?,
	appliedTags: { string },
	message: messageParams.JSON,
	-- files[n]
	-- payload_json
}

export type JSON = typeof(ForumMediaThread.Prototype.build(nil :: any))

return ForumMediaThread.Interface
