local Construct = require("../Utils/Construct")
local Enumerate = require("../Utils/Enumerate")

local DiscordActivity = require("DiscordActivity")

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

function DiscordPresence.Prototype.addActivity(self: DiscordPresence, activity: DiscordActivity.DiscordActivity)
	table.insert(self.activities, activity)
end

function DiscordPresence.Prototype.removeActivity(self: DiscordPresence, activity: DiscordActivity.DiscordActivity)
	local index = table.find(self.activities, activity)

	if index then
		table.remove(self.activities)
	end
end

function DiscordPresence.Prototype.setStatus(self: DiscordPresence, status: string)
	self.status = status
end

function DiscordPresence.Prototype.setAfk(self: DiscordPresence, status: boolean)
	self.idle = status
end

function DiscordPresence.Prototype.setSince(self: DiscordPresence, delta: number)
	self.since = delta
end

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

function DiscordPresence.Interface.new()
	return Construct({
		activities = {}
	}, DiscordPresence.Prototype)
end

export type DiscordPresence = typeof(DiscordPresence.Prototype) & {
	activities: { DiscordActivity.DiscordActivity }
}

return DiscordPresence.Interface