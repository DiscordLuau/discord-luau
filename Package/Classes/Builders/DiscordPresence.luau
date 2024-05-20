local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

local DiscordActivity = require("DiscordActivity")

--[=[
	@class DiscordPresence

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordPresence = {}

DiscordPresence.Type = "DiscordPresence"

DiscordPresence.Interface = {}
DiscordPresence.Prototype = {}

DiscordPresence.Prototype.type = "DiscordPresence"

DiscordPresence.Interface.Status = Enumerate.new({
	Online = "online",
	DoNotDisturb = "dnd",
	Idle = "idle",
	Invisible = "invisible",
	Offline = "offline",
})

--[=[
	@method addActivity
	@within DiscordPresence

	@param activity !DiscordActivity

	@return DiscordPresence

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresence.Prototype.addActivity(self: DiscordPresence, activity: DiscordActivity.DiscordActivity)
	table.insert(self.activities, activity)

	return self
end

--[=[
	@method setStatus
	@within DiscordPresence

	@param status boolean

	@return DiscordPresence

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresence.Prototype.setStatus(self: DiscordPresence, status: string)
	self.status = status

	return self
end

--[=[
	@method setAfk
	@within DiscordPresence

	@param isAfk boolean

	@return DiscordPresence

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresence.Prototype.setAfk(self: DiscordPresence, isAfk: boolean)
	self.idle = isAfk

	return self
end

--[=[
	@method setSince
	@within DiscordPresence

	@param delta number

	@return DiscordPresence

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresence.Prototype.setSince(self: DiscordPresence, delta: number)
	self.since = delta

	return self
end

--[=[
	@method toJSONObject
	@within DiscordPresence

	@return { any }

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresence.Prototype.toJSONObject(self: DiscordPresence)
	local activities = {}

	for index, activity in self.activities :: { DiscordActivity.DiscordActivity } do
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
	@within DiscordPresence

	@return { any }

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordPresence.Interface.new(): DiscordPresence
	return Construct({
		activities = {}
	}, DiscordPresence.Prototype)
end

export type DiscordPresence = typeof(DiscordPresence.Prototype) & {
	activities: { DiscordActivity.DiscordActivity },
	since: number?,
	idle: boolean?,
	status: string?
}

return DiscordPresence.Interface