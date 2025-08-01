--[=[
	@class Builders.Activity
	@__index Prototype

	Implementation of Discord Activity as a Luau builder.

	https://discord.com/developers/docs/events/gateway-events#activity-object
	
	Note: Only YouTube and Twitch URLs are allowed for streaming.
]=]

local apiTypes = require("../lune_packages/api_types")

local Activity = {}

Activity.Prototype = {}
Activity.Interface = {}

--[=[
	@within Builders.Activity

	Sets the name of the activity.
]=]
function Activity.Prototype.setActivityName(self: Activity, name: string): Activity
	self.name = name

	return self
end

--[=[
	@within Builders.Activity

	Sets the type of the activity.
]=]
function Activity.Prototype.setActivityType(self: Activity, activityType: apiTypes.ActivityType): Activity
	assert(
		apiTypes.client.ActivityType[activityType],
		`Expected ActivityType to be one of Game, Streaming, Listening, Watching or Competing`
	)

	self.activityType = activityType

	return self
end

--[=[
	@within Builders.Activity

	Sets the streaming URL of the activity. Only YouTube and Twitch URLs are allowed.
]=]
function Activity.Prototype.setStreamingURL(self: Activity, streamURL: string): Activity
	local hasYouTube = string.find(streamURL, "youtube.com") ~= nil
	local hasTwitch = string.find(streamURL, "twitch.tv") ~= nil

	assert(hasYouTube or hasTwitch, `Expected either Twitch or YouTube for streaming URLs!`)

	self.streamingURL = streamURL

	return self
end

--[=[
	@within Builders.Activity

	Builds the activity JSON payload that can be parsed by the Discord API.
]=]
function Activity.Prototype.build(self: Activity): JSON
	assert(self.activityType ~= nil, `Activity requires ActivityType`)
	assert(self.name ~= nil, `Activity requires Name`)

	return {
		name = self.name,
		url = self.streamingURL,
		type = apiTypes.client.ActivityType[self.activityType],
	}
end

--[=[
	@within Builders.Activity

	Creates a new Activity.

	```luau
	local activity = Activity.new({
		name = "Playing a game",
		activityType = "Game",
		streamingURL = "https://twitch.tv/example"
	})
	```
]=]
function Activity.Interface.new(resource: {
	name: string?,
	activityType: apiTypes.ActivityType?,
	streamingURL: string?,
}?): Activity
	local self = setmetatable(
		{
			--[=[
				@prop name string
				@within Builders.Activity
				The name of the activity that is displayed.
			]=]
			name = nil,

			--[=[
				@prop activityType api_types.ActivityType
				@within Builders.Activity
				The type of activity being performed.
			]=]
			activityType = nil,

			--[=[
				@prop streamingURL string?
				@within Builders.Activity
				The URL of the stream, only YouTube and Twitch URLs are supported.
			]=]
			streamingURL = nil,
		} :: Activity,
		{ __index = Activity.Prototype }
	)

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
