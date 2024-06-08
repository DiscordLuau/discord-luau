local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

local ResolvableType = require("../../Enums/ResolveableType")
local Resolvable = require("../Network/Resolvable")

--[=[
	@class Builders.ActivityBuilder

	ActivityBuilder is used to construct an activity object for a Discord bot - including name, type, and streaming URL.

	Usage:
	```lua
	local activity = ActivityBuilder.new()
		:setActivityName("Playing a game")
		:setActivityType(ActivityBuilder.Type.Game)
		:setStreamingURL("https://twitch.tv/example")
	```
]=]
local ActivityBuilder = {}

ActivityBuilder.Interface = {}
ActivityBuilder.Prototype = {}

ActivityBuilder.Prototype.type = "ActivityBuilder"

--[=[
	@prop Type table
	@within Builders.ActivityBuilder

	An enumeration of activity types.

	- Game: 0
	- Streaming: 1
	- Listening: 2
	- Watching: 3
	- Competing: 5
]=]
ActivityBuilder.Interface.Type = Enumerate.new({
	Game = 0,
	Streaming = 1,
	Listening = 2,
	Watching = 3,
	Competing = 5,
})

--[=[
	Sets the name of the activity.
	
	@method setActivityName
	@param activityName string -- The name of the activity.
	@within Builders.ActivityBuilder
	@return Builders.ActivityBuilder -- Returns the ActivityBuilder instance for method chaining.
]=]
function ActivityBuilder.Prototype.setActivityName(self: ActivityBuilder, activityName: string)
	self.name = activityName

	return self
end

--[=[
	Sets the type of the activity.
	
	@method setActivityType
	@param activityType number -- The type of the activity.
	@within Builders.ActivityBuilder
	@return Builders.ActivityBuilder -- Returns the ActivityBuilder instance for method chaining.
]=]
function ActivityBuilder.Prototype.setActivityType(self: ActivityBuilder, activityType: number)
	ActivityBuilder.Interface.Type:Assert(activityType)

	self.activityType = activityType

	return self
end

--[=[
	Sets the streaming URL of the activity. Only YouTube and Twitch URLs are allowed.
	
	@method setStreamingURL
	@param streamURL string -- The streaming URL.
	@within Builders.ActivityBuilder
	@return Builders.ActivityBuilder -- Returns the ActivityBuilder instance for method chaining.
]=]
function ActivityBuilder.Prototype.setStreamingURL(self: ActivityBuilder, streamURL: string)
	if not string.find(streamURL, "youtube.com") and not string.find(streamURL, "twitch.tv") then
		return
	end

	self.streamingURL = streamURL

	return self
end

--[=[
	Converts the activity to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.ActivityBuilder
	@return Network.Resolvable
]=]
function ActivityBuilder.Prototype.toPayloadObject(self: ActivityBuilder)
	return Resolvable.new(ResolvableType.JSON, {
		name = self.name or "",
		type = self.activityType or 0,
		url = self.streamingURL,
	})
end

--[=[
	Creates a new instance of ActivityBuilder.
	
	@function new
	@within Builders.ActivityBuilder
	@return Builders.ActivityBuilder -- A new instance of ActivityBuilder.
]=]
function ActivityBuilder.Interface.new()
	return (
		Construct({
			name = "Discord-Luau",
			activityType = 0,
			streamingURL = nil,
		}, ActivityBuilder.Prototype) :: unknown
	) :: ActivityBuilder
end

export type ActivityBuilder = typeof(ActivityBuilder.Prototype) & {
	streamingURL: string?,
	activityType: number,
	name: string,
}

return ActivityBuilder.Interface
