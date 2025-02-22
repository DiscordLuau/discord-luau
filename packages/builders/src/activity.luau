--[[
	Implementation of Discord Activity as a Luau builder.

	https://discord.com/developers/docs/events/gateway-events#activity-object
	
	Note: Only YouTube and Twitch URLs are allowed for streaming.
]]

local apiTypes = require("../lune_packages/api_types")

local Activity = {}

Activity.Prototype = {}
Activity.Interface = {}

--[[
	Sets the name of the activity.
]]
function Activity.Prototype.setActivityName(self: Activity, name: string): Activity
	self.name = name

	return self
end

--[[
	Sets the type of the activity.
]]
function Activity.Prototype.setActivityType(self: Activity, activityType: apiTypes.ActivityType): Activity
	assert(
		apiTypes.client.ActivityType[activityType],
		`Expected ActivityType to be one of Game, Streaming, Listening, Watching or Competing`
	)

	self.activityType = activityType

	return self
end

--[[
	Sets the streaming URL of the activity. Only YouTube and Twitch URLs are allowed.
]]
function Activity.Prototype.setStreamingURL(self: Activity, streamURL: string): Activity
	local hasYouTube = string.find(streamURL, "youtube.com") ~= nil
	local hasTwitch = string.find(streamURL, "twitch.tv") ~= nil

	assert(hasYouTube or hasTwitch, `Expected either Twitch or YouTube for streaming URLs!`)

	self.streamingURL = streamURL

	return self
end

--[[
	Builds the activity JSON payload that can be parsed by the Discord API.
]]
function Activity.Prototype.build(self: Activity): JSON
	assert(self.activityType ~= nil, `Activity requires ActivityType`)
	assert(self.name ~= nil, `Activity requires Name`)

	return {
		name = self.name,
		url = self.streamingURL,
		type = apiTypes.client.ActivityType[self.activityType],
	}
end

--[[
	Creates a new Activity.

	```lua

	```
]]
function Activity.Interface.new(resource: {
	name: string?,
	activityType: apiTypes.ActivityType?,
	streamingURL: string?,
}?): Activity
	local self = setmetatable({} :: Activity, { __index = Activity.Prototype })

	if resource then
		if resource.name then
			self:setActivityName(resource.name)
		end
		if resource.activityType then
			self:setActivityType(resource.activityType)
		end
		if resource.streamingURL then
			self:setStreamingURL(resource.streamingURL)
		end
	end

	return self
end

export type Activity = typeof(Activity.Prototype) & {
	name: string,
	activityType: apiTypes.ActivityType,
	streamingURL: string?,
}

export type JSON = typeof(Activity.Prototype.build(nil :: any))

return Activity.Interface
