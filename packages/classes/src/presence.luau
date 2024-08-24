--[[
	Implementation of the Discord Presence class in Luau

	https://discord.com/developers/docs/topics/gateway-events#update-presence
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")

local activity = require("@classes/activity/activity")

local Presence = {}

Presence.Interface = {}
Presence.Prototype = {}

function Presence.Prototype.sync(self: Presence, presenceData: apiTypes.PresenceObject)
	local activities = {}

	for _, activityData in ipairs(presenceData.activities) do
		table.insert(activities, activity.new(activityData))
	end

	self.activities = activities

	self.since = datetime.fromUnixTimestamp(presenceData.since)
	self.status = presenceData.status
	self.afk = presenceData.afk
end

function Presence.Interface.new(presenceData: apiTypes.PresenceObject): Presence
	local self = setmetatable({} :: Presence, { __index = Presence.Prototype })

	self:sync(presenceData)

	return self
end

export type Presence = typeof(Presence.Prototype) & {
	since: datetime.DateTime,
	activities: { activity.Activity },
	status: string,
	afk: boolean,
}

return Presence.Interface
