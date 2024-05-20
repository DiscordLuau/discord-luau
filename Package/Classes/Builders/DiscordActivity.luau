local Enumerate = require("../../Utils/Enumerate")
local Construct = require("../../Utils/Construct")

--[=[
	@class DiscordActivity

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordActivity = {}

DiscordActivity.Interface = {}
DiscordActivity.Prototype = {}

DiscordActivity.Prototype.type = "DiscordActivity"

--[=[
	@prop Type { ... }
	@within DiscordActivity 
]=]
DiscordActivity.Interface.Type = Enumerate.new({
	Game = 0,
	Streaming = 1,
	Listening = 2,
	Watching = 3,
	Competing = 5,
})

--[=[
	@method setActivityName
	@within DiscordActivity

	@param activityName string

	@return DiscordActivity

	(yet-to-do!)

	```lua

	```
]=]
function DiscordActivity.Prototype.setActivityName(self: DiscordActivity, activityName: string)
	self.name = activityName

	return self
end

--[=[
	@method setActivityType
	@within DiscordActivity

	@param activityType number

	@return DiscordActivity

	(yet-to-do!)

	```lua

	```
]=]
function DiscordActivity.Prototype.setActivityType(self: DiscordActivity, activityType: number)
	assert(DiscordActivity.Interface.Type:Is(activityType), `Expected 'activityType' to of class 'activityType'`)

	self.activityType = activityType

	return self
end

--[=[
	@method setStreamingURL
	@within DiscordActivity

	@param streamURL string

	@return DiscordActivity

	(yet-to-do!)

	```lua

	```
]=]
function DiscordActivity.Prototype.setStreamingURL(self: DiscordActivity, streamURL: string)
	if not string.find(streamURL, "youtube.com") and not string.find(streamURL, "twitch.tv") then
		return
	end

	self.streamingURL = streamURL

	return self
end

--[=[
	@method toJSONObject
	@within DiscordActivity

	@return { ... }

	(yet-to-do!)

	```lua

	```
]=]
function DiscordActivity.Prototype.toJSONObject(self: DiscordActivity)
	return {
		name = self.name or "",
		type = self.activityType or 0,
		url = self.streamingURL
	}
end

--[=[
	@function new
	@within DiscordActivity

	@return DiscordActivity

	(yet-to-do!)

	```lua

	```
]=]
function DiscordActivity.Interface.new()
	return Construct({
		name = "Discord-Luau",
		activityType = 0,
		streamingURL = nil
	}, DiscordActivity.Prototype)
end

export type DiscordActivity = typeof(DiscordActivity.Prototype) & {
	streamingURL: string?,
	activityType: number,
	name: string
}

return DiscordActivity.Interface