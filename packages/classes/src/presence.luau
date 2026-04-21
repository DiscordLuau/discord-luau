--[=[
	@class Classes.Presence
	@__index Prototype

	Implementation of the Discord Presence class in Luau

	https://discord.com/developers/docs/topics/gateway-events#update-presence
]=]

--[=[
	@prop since DateTime
	@within Classes.Presence
	The timestamp when this presence was last updated.
]=]

--[=[
	@prop activities { Classes.Activity }
	@within Classes.Presence
	The activities this user is currently participating in.
]=]

--[=[
	@prop status string
	@within Classes.Presence
	The current status of this user (online, idle, dnd, offline).
]=]

--[=[
	@prop afk boolean
	@within Classes.Presence
	Whether this user is currently marked as AFK.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")

local apiTypes = require("../luau_packages/api_types")

local activity = require("./activity/activity")

local Presence = {}

Presence.Interface = {}
Presence.Prototype = {}

--[=[
	@within Classes.Presence
	@private

	Responsible for syncing data to this presence object. This is typically called by the API when this object is
	created or updated.
]=]
function Presence.Prototype.sync(self: Presence, presenceData: apiTypes.PresenceObject)
	self.since = stdPolyfills.datetime.fromUnixTimestamp(presenceData.since)

	local activities = {}

	for _, activityData in next, presenceData.activities do
		table.insert(activities, activity.new(activityData))
	end

	self.activities = activities

	self.status = presenceData.status

	self.afk = presenceData.afk
end

--[=[
	@within Classes.Presence
	@private

	Responsible for constructing this class.
]=]
function Presence.Interface.new(presenceData: apiTypes.PresenceObject): Presence
	local self = setmetatable({} :: Presence, { __index = Presence.Prototype })

	self:sync(presenceData)

	return self
end

export type Presence = typeof(Presence.Prototype) & {
	since: stdPolyfills.DateTime,
	activities: { activity.Activity },
	status: string,
	afk: boolean,
}

return Presence.Interface
