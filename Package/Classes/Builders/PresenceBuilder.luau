local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

local ActivityBuilder = require("ActivityBuilder")

local ResolvableType = require("../../Enums/ResolveableType")
local Resolvable = require("../Network/Resolvable")

--[=[
	@class Builders.PresenceBuilder

	PresenceBuilder is used to construct a presence object for a Discord bot, including activities, status, and AFK state.

	Usage:
	```lua
	local presence = PresenceBuilder.new()
		:addActivity(ActivityBuilder.new():setName("Playing a game"))
		:setStatus(PresenceBuilder.Status.Online)
		:setAfk(false)
		:setSince(os.time())
	```
]=]
local PresenceBuilder = {}

PresenceBuilder.Type = "PresenceBuilder"

PresenceBuilder.Interface = {}
PresenceBuilder.Prototype = {}

PresenceBuilder.Prototype.type = "PresenceBuilder"

--[=[
	@prop Status table
	@within Builders.PresenceBuilder

	An enumeration of presence statuses.

	- Online: "online"
	- DoNotDisturb: "dnd"
	- Idle: "idle"
	- Invisible: "invisible"
	- Offline: "offline"
]=]
PresenceBuilder.Interface.Status = Enumerate.new({
	Online = "online",
	DoNotDisturb = "dnd",
	Idle = "idle",
	Invisible = "invisible",
	Offline = "offline",
})

--[=[
	Adds an activity to the presence.
	
	@method addActivity
	@param activity ActivityBuilder -- The activity to add.
	@within Builders.PresenceBuilder
	@return Builders.PresenceBuilder -- Returns the PresenceBuilder instance for method chaining.
]=]
function PresenceBuilder.Prototype.addActivity(self: PresenceBuilder, activity: ActivityBuilder.ActivityBuilder)
	table.insert(self.activities, activity)

	return self
end

--[=[
	Sets the status of the presence.
	
	@method setStatus
	@param status string -- The status to set.
	@within Builders.PresenceBuilder
	@return Builders.PresenceBuilder -- Returns the PresenceBuilder instance for method chaining.
]=]
function PresenceBuilder.Prototype.setStatus(self: PresenceBuilder, status: string)
	self.status = status

	return self
end

--[=[
	Sets whether the presence is AFK.
	
	@method setAfk
	@param isAfk boolean -- Whether the presence is AFK.
	@within Builders.PresenceBuilder
	@return Builders.PresenceBuilder -- Returns the PresenceBuilder instance for method chaining.
]=]
function PresenceBuilder.Prototype.setAfk(self: PresenceBuilder, isAfk: boolean)
	self.idle = isAfk

	return self
end

--[=[
	Sets the time since the presence was last updated.

	@method setSince
	@param delta number -- The time since the presence was last updated, in milliseconds.
	@within Builders.PresenceBuilder
	@return Builders.PresenceBuilder -- Returns the PresenceBuilder instance for method chaining.
]=]
function PresenceBuilder.Prototype.setSince(self: PresenceBuilder, delta: number)
	self.since = delta

	return self
end

--[=[
	Converts the presence to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.PresenceBuilder
	@return Network.Resolvable
]=]
function PresenceBuilder.Prototype.toPayloadObject(self: PresenceBuilder)
	local activities = {}

	for index, activity in self.activities :: { ActivityBuilder.ActivityBuilder } do
		activities[index] = activity:toPayloadObject():resolve()
	end

	return Resolvable.new(ResolvableType.JSON, {
		since = self.since or 0,

		activities = activities,
		afk = self.idle or false,
		status = self.status or "online",
	})
end

--[=[
	Creates a new instance of PresenceBuilder.
	
	@function new
	@within Builders.PresenceBuilder
	@return Builders.PresenceBuilder -- A new instance of PresenceBuilder.
]=]
function PresenceBuilder.Interface.new()
	return (Construct({
		activities = {},
	}, PresenceBuilder.Prototype) :: unknown) :: PresenceBuilder
end

export type PresenceBuilder = typeof(PresenceBuilder.Prototype) & {
	activities: { ActivityBuilder.ActivityBuilder },
	since: number?,
	idle: boolean?,
	status: string?,
}

return PresenceBuilder.Interface
