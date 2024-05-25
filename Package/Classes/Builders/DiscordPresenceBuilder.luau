local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

local DiscordActivityBuilder = require("DiscordActivityBuilder")

--[=[
	@class Builders.DiscordPresenceBuilder

	DiscordPresenceBuilder is used to construct a presence object for a Discord bot, including activities, status, and AFK state.

	Usage:
	```lua
	local presence = DiscordPresenceBuilder.new()
		:addActivity(DiscordActivityBuilder.new():setName("Playing a game"))
		:setStatus(DiscordPresenceBuilder.Status.Online)
		:setAfk(false)
		:setSince(os.time())
	```
]=]
local DiscordPresenceBuilder = {}

DiscordPresenceBuilder.Type = "DiscordPresenceBuilder"

DiscordPresenceBuilder.Interface = {}
DiscordPresenceBuilder.Prototype = {}

DiscordPresenceBuilder.Prototype.type = "DiscordPresenceBuilder"

--[=[
	@prop Status table
	@within Builders.DiscordPresenceBuilder

	An enumeration of presence statuses.

	- Online: "online"
	- DoNotDisturb: "dnd"
	- Idle: "idle"
	- Invisible: "invisible"
	- Offline: "offline"
]=]
DiscordPresenceBuilder.Interface.Status = Enumerate.new({
	Online = "online",
	DoNotDisturb = "dnd",
	Idle = "idle",
	Invisible = "invisible",
	Offline = "offline",
})

--[=[
	Adds an activity to the presence.
	
	@method addActivity
	@param activity DiscordActivityBuilder -- The activity to add.
	@within Builders.DiscordPresenceBuilder
	@return Builders.DiscordPresenceBuilder -- Returns the DiscordPresenceBuilder instance for method chaining.
]=]
function DiscordPresenceBuilder.Prototype.addActivity(self: DiscordPresenceBuilder, activity: DiscordActivityBuilder.DiscordActivityBuilder)
	table.insert(self.activities, activity)

	return self
end

--[=[
	Sets the status of the presence.
	
	@method setStatus
	@param status string -- The status to set.
	@within Builders.DiscordPresenceBuilder
	@return Builders.DiscordPresenceBuilder -- Returns the DiscordPresenceBuilder instance for method chaining.
]=]
function DiscordPresenceBuilder.Prototype.setStatus(self: DiscordPresenceBuilder, status: string)
	self.status = status

	return self
end

--[=[
	Sets whether the presence is AFK.
	
	@method setAfk
	@param isAfk boolean -- Whether the presence is AFK.
	@within Builders.DiscordPresenceBuilder
	@return Builders.DiscordPresenceBuilder -- Returns the DiscordPresenceBuilder instance for method chaining.
]=]
function DiscordPresenceBuilder.Prototype.setAfk(self: DiscordPresenceBuilder, isAfk: boolean)
	self.idle = isAfk

	return self
end

--[=[
	Sets the time since the presence was last updated.

	@method setSince
	@param delta number -- The time since the presence was last updated, in milliseconds.
	@within Builders.DiscordPresenceBuilder
	@return Builders.DiscordPresenceBuilder -- Returns the DiscordPresenceBuilder instance for method chaining.
]=]
function DiscordPresenceBuilder.Prototype.setSince(self: DiscordPresenceBuilder, delta: number)
	self.since = delta

	return self
end

--[=[
	Converts the presence to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within Builders.DiscordPresenceBuilder
	@return table -- The JSON representation of the presence.
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
	Creates a new instance of DiscordPresenceBuilder.
	
	@function new
	@within Builders.DiscordPresenceBuilder
	@return Builders.DiscordPresenceBuilder -- A new instance of DiscordPresenceBuilder.
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
