local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class DiscordActivityBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordActivityBuilder = {}

DiscordActivityBuilder.Interface = {}
DiscordActivityBuilder.Prototype = {}

DiscordActivityBuilder.Prototype.type = "DiscordActivityBuilder"

--[=[
	@prop Type { ... }
	@within DiscordActivityBuilder 
]=]
DiscordActivityBuilder.Interface.Type = Enumerate.new({
	Game = 0,
	Streaming = 1,
	Listening = 2,
	Watching = 3,
	Competing = 5,
})

--[=[
	@method setActivityName
	@within DiscordActivityBuilder

	@param activityName string

	@return DiscordActivityBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordActivityBuilder.Prototype.setActivityName(self: DiscordActivityBuilder, activityName: string)
	self.name = activityName

	return self
end

--[=[
	@method setActivityType
	@within DiscordActivityBuilder

	@param activityType number

	@return DiscordActivityBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordActivityBuilder.Prototype.setActivityType(self: DiscordActivityBuilder, activityType: number)
	assert(DiscordActivityBuilder.Interface.Type:Is(activityType), `Expected 'activityType' to of class 'activityType'`)

	self.activityType = activityType

	return self
end

--[=[
	@method setStreamingURL
	@within DiscordActivityBuilder

	@param streamURL string

	@return DiscordActivityBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordActivityBuilder.Prototype.setStreamingURL(self: DiscordActivityBuilder, streamURL: string)
	if not string.find(streamURL, "youtube.com") and not string.find(streamURL, "twitch.tv") then
		return
	end

	self.streamingURL = streamURL

	return self
end

--[=[
	@method toJSONObject
	@within DiscordActivityBuilder

	@return { ... }

	(yet-to-do!)

	```lua

	```
]=]
function DiscordActivityBuilder.Prototype.toJSONObject(self: DiscordActivityBuilder)
	return {
		name = self.name or "",
		type = self.activityType or 0,
		url = self.streamingURL
	}
end

--[=[
	@function new
	@within DiscordActivityBuilder

	@return DiscordActivityBuilder

	(yet-to-do!)

	```lua

	```
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