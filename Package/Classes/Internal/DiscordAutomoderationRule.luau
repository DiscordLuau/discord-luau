local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

--[=[
	@class Internal.DiscordAutomoderationRule

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordAutomoderationRule = {}

DiscordAutomoderationRule.Prototype = {}
DiscordAutomoderationRule.Interface = {}

DiscordAutomoderationRule.Prototype.type = "DiscordAutomoderationRule"

function DiscordAutomoderationRule.Prototype.modifyAsync()

end

function DiscordAutomoderationRule.Prototype.deleteAsync()

end

function DiscordAutomoderationRule.Interface.new(discordClient: any, automoderationData: {
	id: string,
}): DiscordAutomoderationRule
	local self = discordClient.discordCache:getDataOr(CacheType.AutoModeration, automoderationData.id, function()
		return Construct({
			id = automoderationData.id,
	
			discordClient = discordClient
		}, DiscordAutomoderationRule.Prototype)
	end)

	for index, value in automoderationData do
		self[index] = value
	end

	return self
end

export type DiscordAutomoderationRule = typeof(DiscordAutomoderationRule.Prototype) & {
	id: string,
	guildId: string,
	name: string,
	creatorId: string,
	eventType: number,
	triggerType: number,
	enabled: boolean?,
	exemptRoles: { string },
	exemptChannels: { string },
	triggerMetadata: {
		keywordFilter: { string },
		regexPatterns: { string },
		presets: { number },
		allowList: { string },
		mentionTotalLimit: number,
		mentionRaidProtectionEnabled: boolean
	},
	actions: {
		type: number,
		metadata: {
			channelId: string,
			durationSeconds: number,
			customMessage: string?
		}?
	}
}

return DiscordAutomoderationRule.Interface