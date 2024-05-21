local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local DiscordAutomoderationRuleBuilder = require("../Builders/DiscordAutomoderationRuleBuilder")

--[=[
	@class Objects.DiscordAutomoderationRuleBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordAutomoderationRuleBuilder = {}

DiscordAutomoderationRuleBuilder.Prototype = {}
DiscordAutomoderationRuleBuilder.Interface = {}

DiscordAutomoderationRuleBuilder.Prototype.type = "DiscordAutomoderationRuleBuilder"

function DiscordAutomoderationRuleBuilder.Prototype.modifyAsync(self: DiscordAutomoderationRule, moderationRoleBuilder: DiscordAutomoderationRuleBuilder.DiscordAutomoderationRuleBuilder)
	return self.discordClient.discordGateway:patchAsync(
		string.format(DiscordEndpoints.BotModifyAutomoderationRule, self.guildId, self.id),
		moderationRoleBuilder:toJSONObject()
	)
end

function DiscordAutomoderationRuleBuilder.Prototype.deleteAsync(self: DiscordAutomoderationRule)
	return self.discordClient.discordGateway:postAsync(
		string.format(DiscordEndpoints.BotDeleteAutomoderationRule, self.guildId, self.id)
	)
end

function DiscordAutomoderationRuleBuilder.Interface.new(discordClient: any, automoderationData: {
	id: string,
}): DiscordAutomoderationRule
	local self = discordClient.discordCache:getDataOr(CacheType.AutoModeration, automoderationData.id, function()
		return Construct({
			id = automoderationData.id,
	
			discordClient = discordClient
		}, DiscordAutomoderationRuleBuilder.Prototype)
	end)

	for index, value in automoderationData do
		self[index] = value
	end

	return self
end

export type DiscordAutomoderationRule = typeof(DiscordAutomoderationRuleBuilder.Prototype) & {
	discordClient: any,

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

return DiscordAutomoderationRuleBuilder.Interface