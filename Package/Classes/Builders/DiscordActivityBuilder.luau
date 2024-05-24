local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class DiscordActivityBuilder

	DiscordActivityBuilder is used to construct an activity object for a Discord bot, including name, type, and streaming URL.

	Usage:
	```lua
	local activity = DiscordActivityBuilder.new()
		:setActivityName("Playing a game")
		:setActivityType(DiscordActivityBuilder.Type.Game)
		:setStreamingURL("https://twitch.tv/example")
	```
]=]
local DiscordActivityBuilder = {}

DiscordActivityBuilder.Interface = {}
DiscordActivityBuilder.Prototype = {}

DiscordActivityBuilder.Prototype.type = "DiscordActivityBuilder"

--[=[
	@prop Type table
	@within DiscordActivityBuilder

	An enumeration of activity types.

	- Game: 0
	- Streaming: 1
	- Listening: 2
	- Watching: 3
	- Competing: 5
]=]
DiscordActivityBuilder.Interface.Type = Enumerate.new({
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
	@within DiscordActivityBuilder
	@return DiscordActivityBuilder -- Returns the DiscordActivityBuilder instance for method chaining.
]=]
function DiscordActivityBuilder.Prototype.setActivityName(self: DiscordActivityBuilder, activityName: string)
	self.name = activityName

	return self
end

--[=[
	Sets the type of the activity.
	
	@method setActivityType
	@param activityType number -- The type of the activity.
	@within DiscordActivityBuilder
	@return DiscordActivityBuilder -- Returns the DiscordActivityBuilder instance for method chaining.
]=]
function DiscordActivityBuilder.Prototype.setActivityType(self: DiscordActivityBuilder, activityType: number)
	assert(DiscordActivityBuilder.Interface.Type:Is(activityType), `Expected 'activityType' to be of class 'activityType'`)

	self.activityType = activityType

	return self
end

--[=[
	Sets the streaming URL of the activity. Only YouTube and Twitch URLs are allowed.
	
	@method setStreamingURL
	@param streamURL string -- The streaming URL.
	@within DiscordActivityBuilder
	@return DiscordActivityBuilder -- Returns the DiscordActivityBuilder instance for method chaining.
]=]
function DiscordActivityBuilder.Prototype.setStreamingURL(self: DiscordActivityBuilder, streamURL: string)
	if not string.find(streamURL, "youtube.com") and not string.find(streamURL, "twitch.tv") then
		return
	end

	self.streamingURL = streamURL

	return self
end

--[=[
	Converts the activity to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within DiscordActivityBuilder
	@return table -- The JSON representation of the activity.
]=]
function DiscordActivityBuilder.Prototype.toJSONObject(self: DiscordActivityBuilder)
	return {
		name = self.name or "",
		type = self.activityType or 0,
		url = self.streamingURL
	}
end

--[=[
	Creates a new instance of DiscordActivityBuilder.
	
	@function new
	@within DiscordActivityBuilder
	@return DiscordActivityBuilder -- A new instance of DiscordActivityBuilder.
]=]
function DiscordActivityBuilder.Interface.new()
	return Construct({
		name = "Discord-Luau",
		activityType = 0,
		streamingURL = nil
	}, DiscordActivityBuilder.Prototype)
end

export type DiscordActivityBuilder = typeof(DiscordActivityBuilder.Prototype) & {
	streamingURL: string?,
	activityType: number,
	name: string
}

return DiscordActivityBuilder.Interface
