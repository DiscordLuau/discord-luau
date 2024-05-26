local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local AutomoderationRuleBuilder = require("../Builders/AutomoderationRuleBuilder")

--[=[
	@class Objects.DiscordAutomoderationRule

	The `DiscordAutomoderationRule` class provides methods to interact with Discord auto-moderation rules, including modifying and deleting rules.
]=]

--[=[
	@prop id string
	@within Objects.DiscordAutomoderationRule
]=]

--[=[
	@prop guildId sring
	@within Objects.DiscordAutomoderationRule
]=]

--[=[
	@prop name string
	@within Objects.DiscordAutomoderationRule
]=]

--[=[
	@prop eventType number
	@within Objects.DiscordAutomoderationRule
]=]

--[=[
	@prop triggerType number
	@within Objects.DiscordAutomoderationRule
]=]

--[=[
	@prop enabled boolean
	@within Objects.DiscordAutomoderationRule
]=]

--[=[
	@prop exemptRoles { string }
	@within Objects.DiscordAutomoderationRule
]=]

--[=[
	@prop exemptChannels { string }
	@within Objects.DiscordAutomoderationRule
]=]

--[=[
	@prop triggerMetadata TriggerMetadata
	@within Objects.DiscordAutomoderationRule
]=]

--[=[
	@prop actions Actions
	@within Objects.DiscordAutomoderationRule
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
function DiscordAutomoderationRule.Prototype.modifyAsync(
	self: DiscordAutomoderationRule,
	moderationRoleBuilder: AutomoderationRuleBuilder.AutomoderationRuleBuilder
)
	return self.discordClient.discordGateway:patchAsync(
		string.format(DiscordEndpoints.BotModifyAutomoderationRule, self.guildId, self.id),
		moderationRoleBuilder:toPayloadObject()
	)
end

--[=[
	@method deleteAsync
	@within Objects.DiscordAutomoderationRule
	@return Future<CommandResponse>

	Deletes an existing auto-moderation rule.
]=]
function DiscordAutomoderationRule.Prototype.deleteAsync(self: DiscordAutomoderationRule)
	return self.discordClient.discordGateway:deletAsync(
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
function DiscordAutomoderationRule.Interface.new(
	discordClient: any,
	automoderationData: {
		id: string,
	}
): DiscordAutomoderationRule
	local self = discordClient.discordCache:getDataOr(CacheType.AutoModeration, automoderationData.id, function()
		return Construct({
			id = automoderationData.id,

			discordClient = discordClient,
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
		mentionRaidProtectionEnabled: boolean,
	},
	actions: {
		type: number,
		metadata: {
			channelId: string,
			durationSeconds: number,
			customMessage: string?,
		}?,
	},
}

return DiscordAutomoderationRule.Interface
