local DiscordActivity = {}

DiscordActivity.Type = "DiscordActivity"

DiscordActivity.Internal = {}
DiscordActivity.Interface = {}
DiscordActivity.Prototype = {
	Internal = DiscordActivity.Internal,
}

DiscordActivity.Interface.ActivityType = {
	Game = 0,
	Streaming = 1,
	Listening = 2,
	Watching = 3,
	Custom = 4,
	Competing = 5,
}

function DiscordActivity.Prototype:SetActivityName(activity) end

function DiscordActivity.Prototype:SetActivityType(activityType) end

function DiscordActivity.Prototype:SetStreamingURL(streamURL) end

function DiscordActivity.Prototype:SetTimestamps(streamURL) end

function DiscordActivity.Prototype:SetApplicationId(applicationId) end

function DiscordActivity.Prototype:SetActivityDetails(detail) end

function DiscordActivity.Prototype:SetActivityState(state) end

function DiscordActivity.Prototype:SetActivityEmoji(emojiName, emojiId, emojiAnimated) end

function DiscordActivity.Prototype:SetActivityParty(partyName, partySize) end

function DiscordActivity.Prototype:SetActivityLargeImage(largeImageAsset, largeImageText) end

function DiscordActivity.Prototype:SetActivitySmallImage(largeImageAsset, largeImageText) end

function DiscordActivity.Prototype:SetActivityJoinSecret(joinSecret) end

function DiscordActivity.Prototype:SetActivitySpectateSecret(joinSecret) end

function DiscordActivity.Prototype:SetActivityMatchSecret(joinSecret) end

function DiscordActivity.Prototype:AddButton(buttonLabel, buttonUrl) end

function DiscordActivity.Prototype:RemoveButton(buttonLabel, buttonUrl) end

function DiscordActivity.Prototype:ToString()
	return `{DiscordActivity.Type}<{"a"}>`
end

function DiscordActivity.Interface.new()
	return setmetatable({
		Object = {},
	}, {
		__index = DiscordActivity.Prototype,
		__type = DiscordActivity.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordActivity.Interface
