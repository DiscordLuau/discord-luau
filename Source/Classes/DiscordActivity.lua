local Enumeration = require("../Dependencies/Enumeration")

local DiscordActivity = {}

DiscordActivity.Type = "DiscordActivity"

DiscordActivity.Internal = {}
DiscordActivity.Interface = {}
DiscordActivity.Prototype = {
	Internal = DiscordActivity.Internal,
}

DiscordActivity.Interface.Type = Enumeration.new({
	Game = 0,
	Streaming = 1,
	Listening = 2,
	Watching = 3,
	Competing = 5,
})

function DiscordActivity.Prototype:SetActivityName(activityName)
	self.Name = activityName
end

function DiscordActivity.Prototype:SetActivityType(activityType)
	assert(DiscordActivity.Interface.Type:Is(activityType), `Expected 'activityType' to of class 'ActivityType'`)

	self.ActivityType = activityType
end

function DiscordActivity.Prototype:SetStreamingURL(streamURL)
	if not string.find(streamURL, "youtube.com") and not string.find(streamURL, "twitch.tv") then
		return
	end

	self.StreamingURL = streamURL
end

function DiscordActivity.Prototype:ToJSONObject()
	return {
		name = self.Name or "",
		type = self.ActivityType or 0,
		url = self.StreamingURL
	}
end

function DiscordActivity.Prototype:ToString()
	return `{DiscordActivity.Type}<{self.Name or "Unknown Activity"}>`
end

function DiscordActivity.Interface.new()
	return setmetatable({ }, {
		__index = DiscordActivity.Prototype,
		__type = DiscordActivity.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordActivity.Interface
