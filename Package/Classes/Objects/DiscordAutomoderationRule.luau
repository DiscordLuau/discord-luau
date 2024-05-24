local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local DiscordAutomoderationRuleBuilder = require("../Builders/DiscordAutomoderationRuleBuilder")

--[=[
	@class Objects.DiscordAutomoderationRule

	The `DiscordAutomoderationRule` class provides methods to interact with Discord auto-moderation rules, including modifying and deleting rules.

	@field id string The unique identifier of the auto-moderation rule.
	@field guildId string The ID of the guild where the rule is applied.
	@field name string The name of the auto-moderation rule.
	@field creatorId string The ID of the creator of the rule.
	@field eventType number The type of event that triggers the rule.
	@field triggerType number The type of trigger for the rule.
	@field enabled boolean? Whether the rule is enabled.
	@field exemptRoles {string} Roles exempt from the rule.
	@field exemptChannels {string} Channels exempt from the rule.
	@field triggerMetadata table Metadata for the trigger, including keyword filters, regex patterns, presets, allow list, mention limits, and raid protection.
	@field actions table Actions to be taken when the rule is triggered, including type and metadata such as channel ID, duration, and custom message.
]=]

local DiscordAutomoderationRule = {}

DiscordAutomoderationRule.Prototype = {}
DiscordAutomoderationRule.Interface = {}

DiscordAutomoderationRule.Prototype.type = "DiscordAutomoderationRule"

--[=[
	@method modifyAsync
	@param moderationRoleBuilder DiscordAutomoderationRule.DiscordAutomoderationRule The builder for the modified rule.
	@within Objects.DiscordAutomoderationRule
	@return Future<CommandResponse>

	Modifies an existing auto-moderation rule.
]=]
function DiscordAutomoderationRule.Prototype.modifyAsync(self: DiscordAutomoderationRule, moderationRoleBuilder: DiscordAutomoderationRuleBuilder.DiscordAutomoderationRuleBuilder)
	return self.discordClient.discordGateway:patchAsync(
		string.format(DiscordEndpoints.BotModifyAutomoderationRule, self.guildId, self.id),
		moderationRoleBuilder:toJSONObject()
	)
end

--[=[
	@method deleteAsync
	@within Objects.DiscordAutomoderationRule
	@return Future<CommandResponse>

	Deletes an existing auto-moderation rule.
]=]
function DiscordAutomoderationRule.Prototype.deleteAsync(self: DiscordAutomoderationRule)
	return self.discordClient.discordGateway:postAsync(
		string.format(DiscordEndpoints.BotDeleteAutomoderationRule, self.guildId, self.id)
	)
end

--[=[
	@function new
	@param discordClient any The Discord client instance.
	@param automoderationData table The data for the auto-moderation rule.
	@within Objects.DiscordAutomoderationRule
	@return DiscordAutomoderationRule

	Creates a new instance of the DiscordAutomoderationRule.
]=]
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

return DiscordAutomoderationRule.Interface
