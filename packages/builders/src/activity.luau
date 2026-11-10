--[=[
	@class Builders.Activity
	@__index Prototype

	Implementation of Discord Activity as a Luau builder.

	https://discord.com/developers/docs/events/gateway-events#activity-object
	
	Note: Only YouTube and Twitch URLs are allowed for streaming.
]=]

--[=[
	@prop name string
	@within Builders.Activity
	The name of the activity that is displayed. A custom status does not show it, so it defaults to "Custom Status" there.
]=]

--[=[
	@prop activityType api_types.ActivityType
	@within Builders.Activity
	The type of activity being performed.
]=]

--[=[
	@prop streamingURL string?
	@within Builders.Activity
	The URL of the stream, only YouTube and Twitch URLs are supported.
]=]

--[=[
	@prop state string?
	@within Builders.Activity
	The text of a custom status, or the party status shown under the name on other activity types.
]=]

local apiTypes = require("../luau_packages/api_types")

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
		`Expected ActivityType to be one of Game, Streaming, Listening, Watching, Custom or Competing`
	)

	self.activityType = activityType

	return self
end

--[=[
	@within Builders.Activity

	Sets the streaming URL of the activity. Only YouTube and Twitch URLs are allowed.
]=]
function Activity.Prototype.setStreamingURL(self: Activity, streamURL: string): Activity
	local supportedHost = string.find(streamURL, "youtube.com") or string.find(streamURL, "twitch.tv")

	assert(supportedHost, `Expected either Twitch or YouTube for streaming URLs!`)

	self.streamingURL = streamURL

	return self
end

--[=[
	@within Builders.Activity

	Sets the state of the activity: the text of a custom status, or the party status on other activity types.
]=]
function Activity.Prototype.setState(self: Activity, state: string): Activity
	self.state = state

	return self
end

--[=[
	@within Builders.Activity

	Builds the activity JSON payload that can be parsed by the Discord API.
]=]
function Activity.Prototype.build(self: Activity): JSON
	local name = if self.activityType == "Custom" then self.name or "Custom Status" else self.name

	assert(self.activityType, `Activity requires ActivityType`)
	assert(name, `Activity requires Name`)

	return {
		name = name,
		url = self.streamingURL,
		type = apiTypes.client.ActivityType[self.activityType],
		state = self.state,
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

	local customStatus = Activity.new({
		activityType = "Custom",
		state = "Watching over the staff team!"
	})
	```
]=]
function Activity.Interface.new(resource: {
	name: string?,
	activityType: apiTypes.ActivityType?,
	streamingURL: string?,
	state: string?,
}?): Activity
	local self = setmetatable(
		{
			name = nil,

			activityType = nil,

			streamingURL = nil,

			state = nil,
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

		if resource.state then
			self:setState(resource.state)
		end
	end

	return self
end

export type Activity = typeof(Activity.Prototype) & {
	name: string,
	activityType: apiTypes.ActivityType,
	streamingURL: string?,
	state: string?,
}

export type JSON = typeof(Activity.Prototype.build(nil :: any))

return Activity.Interface
