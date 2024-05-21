local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

local DiscordActivityBuilder = require("DiscordActivityBuilder")

--[=[
	@class DiscordPresenceBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordPresenceBuilder = {}

DiscordPresenceBuilder.Type = "DiscordPresenceBuilder"

DiscordPresenceBuilder.Interface = {}
DiscordPresenceBuilder.Prototype = {}

DiscordPresenceBuilder.Prototype.type = "DiscordPresenceBuilder"

DiscordPresenceBuilder.Interface.Status = Enumerate.new({
	Online = "online",
	DoNotDisturb = "dnd",
	Idle = "idle",
	Invisible = "invisible",
	Offline = "offline",
})

--[=[
	@method addActivity
	@within DiscordPresenceBuilder

	@param activity !DiscordActivityBuilder

	@return DiscordPresenceBuilder

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresenceBuilder.Prototype.addActivity(self: DiscordPresenceBuilder, activity: DiscordActivityBuilder.DiscordActivityBuilder)
	table.insert(self.activities, activity)

	return self
end

--[=[
	@method setStatus
	@within DiscordPresenceBuilder

	@param status boolean

	@return DiscordPresenceBuilder

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresenceBuilder.Prototype.setStatus(self: DiscordPresenceBuilder, status: string)
	self.status = status

	return self
end

--[=[
	@method setAfk
	@within DiscordPresenceBuilder

	@param isAfk boolean

	@return DiscordPresenceBuilder

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresenceBuilder.Prototype.setAfk(self: DiscordPresenceBuilder, isAfk: boolean)
	self.idle = isAfk

	return self
end

--[=[
	@method setSince
	@within DiscordPresenceBuilder

	@param delta number

	@return DiscordPresenceBuilder

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresenceBuilder.Prototype.setSince(self: DiscordPresenceBuilder, delta: number)
	self.since = delta

	return self
end

--[=[
	@method toJSONObject
	@within DiscordPresenceBuilder

	@return { any }

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresenceBuilder.Prototype.toJSONObject(self: DiscordPresenceBuilder)
	local activities = {}

	for index, activity in self.activities :: { DiscordActivityBuilder.DiscordActivityBuilder } do
		activities[index] = activity:toJSONObject()
	end

	return {
		since = self.since or 0,

		activities = activities,
		afk = self.idle or false,
		status = self.status or "online",
	}
end

--[=[
	@function new
	@within DiscordPresenceBuilder

	@return { any }

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresenceBuilder.Interface.new(): DiscordPresenceBuilder
	return Construct({
		activities = {}
	}, DiscordPresenceBuilder.Prototype)
end

export type DiscordPresenceBuilder = typeof(DiscordPresenceBuilder.Prototype) & {
	activities: { DiscordActivityBuilder.DiscordActivityBuilder },
	since: number?,
	idle: boolean?,
	status: string?
}

return DiscordPresenceBuilder.Interface