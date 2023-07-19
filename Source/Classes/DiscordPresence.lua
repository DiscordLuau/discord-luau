local DiscordPresence = {}

DiscordPresence.Type = "DiscordPresence"

DiscordPresence.Internal = {}
DiscordPresence.Interface = {}
DiscordPresence.Prototype = {
	Internal = DiscordPresence.Internal,
}

DiscordPresence.Interface.Status = {
	Online = "online",
	DoNotDisturb = "dnd",
	Idle = "idle",
	Invisible = "invisible",
	Offline = "offline",
}

function DiscordPresence.Prototype:AddActivity(activity)
	table.insert(self.Activities, activity)
end

function DiscordPresence.Prototype:RemoveActivity(activity)
	local index = table.find(self.Activities, activity)

	if index then
		table.remove(self.Activities)
	end
end

function DiscordPresence.Prototype:SetStatus(status)
	self.Status = status
end

function DiscordPresence.Prototype:ToJSONObject()
	local activities = {}

	for index, activity in self.Activities do
		activities[index] = activity:ToJSONObject()
	end

	return {
		since = self.Since or 0,

		activities = activities,
		afk = self.Idle or false,
		status = self.Status or "online",
	}
end

function DiscordPresence.Prototype:ToString()
	return `{DiscordPresence.Type}<{"a"}>`
end

function DiscordPresence.Interface.new()
	return setmetatable({
		Activities = {}
	}, {
		__index = DiscordPresence.Prototype,
		__type = DiscordPresence.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordPresence.Interface
