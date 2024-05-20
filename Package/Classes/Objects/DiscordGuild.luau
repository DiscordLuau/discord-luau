local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local ApplicationCommandBuilder = require("../Builders/ApplicationCommandBuilder")
local DiscordAutomoderationRuleBuilder = require("../Builders/DiscordAutomoderationRuleBuilder")

local DiscordEmoji = require("DiscordEmoji")
local DiscordGuildRole = require("DiscordGuildRole")
local DiscordChannel = require("DiscordChannel")
local DiscordUser = require("DiscordUser")

local DiscordGuildMember = require("DiscordGuildMember")

local DiscordAutomoderationRule = require("DiscordAutomoderationRule")

local Future = require("../../Vendor/Future")

--[=[
	@class Objects.DiscordGuild

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordGuild = {}

DiscordGuild.Prototype = {}
DiscordGuild.Interface = {}

DiscordGuild.Prototype.type = "DiscordGuild"

function DiscordGuild.Prototype.createSlashCommandAsync(self: DiscordGuild, command: ApplicationCommandBuilder.ApplicationCommandBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway:postAsync(
			string.format(DiscordEndpoints.CreateGuildApplicationCommand, self.discordClient.discordApplication.id, self.id),
			command:toJSONObject()
		):await()
	end)
end

function DiscordGuild.Prototype.deleteSlashCommandAsync(self: DiscordGuild, commandId: string)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(
			string.format(DiscordEndpoints.DeleteGuildApplicationCommand, self.discordClient.discordApplication.id, self.id, commandId)
		):await()
	end)
end

function DiscordGuild.Prototype.editSlashCommandAsync(self: DiscordGuild, commandId: string, command: ApplicationCommandBuilder.ApplicationCommandBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway:patchAsync(
			string.format(DiscordEndpoints.EditGuildApplicationCommand, self.discordClient.discordApplication.id, self.id, commandId),
			command:toJSONObject()
		):await()
	end)
end

function DiscordGuild.Prototype.fetchSlashCommandsAsync(self: DiscordGuild)
	return Future.try(function()
		return self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.GetGuildApplicationCommands, self.discordClient.discordApplication.id, self.id)
		):await()
	end)
end

function DiscordGuild.Prototype.fetchGuildChannels(self: DiscordGuild)
	return Future.try(function()
		return self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.GetGuildApplicationCommands, self.discordClient.discordApplication.id, self.id)
		):await()
	end)
end

function DiscordGuild.Prototype.setSlashCommandsAsync(self: DiscordGuild, commands: { ApplicationCommandBuilder.ApplicationCommandBuilder })
	return Future.try(function()
		local allCommands = self:fetchSlashCommandsAsync():await()

		local commandsToUpdate = {}
		local commandsToCreate = {}
		local commandsToDestroy = {}

		for _, commandObject0 in allCommands do
			local commandFoundInCommandsArray
			local commandReference

			for _, commandObject1 in commands do
				if commandObject0.name ~= commandObject1.commandName then
					continue
				end

				commandReference = commandObject1
				commandFoundInCommandsArray = true
				
				break
			end

			if commandFoundInCommandsArray then
				commandsToUpdate[commandObject0.id] = commandReference
			else
				table.insert(commandsToDestroy, commandObject0)
			end
		end

		for _, commandObject0 in commands do
			local commandFoundInUpdateCommandsArray

			for _, commandObject1 in commandsToUpdate do
				if commandObject0.commandName ~= commandObject1.commandName then
					continue
				end

				commandFoundInUpdateCommandsArray = true

				break
			end

			if not commandFoundInUpdateCommandsArray then
				table.insert(commandsToCreate, commandObject0)
			end
		end

		for _, commandStruct in commandsToDestroy do
			self:deleteSlashCommandAsync(commandStruct.id):await()
		end

		for commandId: string, command: ApplicationCommandBuilder.ApplicationCommandBuilder in commandsToUpdate do
			self:editSlashCommandAsync(commandId, command):await()
		end

		for _, command: ApplicationCommandBuilder.ApplicationCommandBuilder in commandsToCreate do
			self:createSlashCommandAsync(command):await()
		end
	end)
end

function DiscordGuild.Prototype.getGuildAuditLogs(self: DiscordGuild, commands: { ApplicationCommandBuilder.ApplicationCommandBuilder })
	return Future.try(function()
		local guildAuditLogs = self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.GetGuildAuditLogs, self.id)
		):await()

		for index, channelObject in guildAuditLogs.threads do
			guildAuditLogs.threads[index] = DiscordChannel.new(self.discordClient, channelObject)
		end

		for index, userObject in guildAuditLogs.users do
			guildAuditLogs.users[index] = DiscordUser.new(self.discordClient, userObject)
		end

		return guildAuditLogs
	end)
end

function DiscordGuild.Prototype.modifyAsync(self: DiscordGuild, guildSchema: DiscordGuildSchema)
	return Future.try(function()
		return self.discordClient.discordGateway:patchAsync(string.format(DiscordEndpoints.BotModifyGuild, self.id), {
			name = guildSchema.name,
			region = guildSchema.region,
			verification_level = guildSchema.verificationLevel,
			default_message_notifications = guildSchema.defaultMessageNotifications,
			explicit_content_filter = guildSchema.explicitContentFilter,
			afk_channel_id = guildSchema.afkChannelId,
			afk_timeout = guildSchema.afkTimeout,
			owner_id = guildSchema.ownerId,
			system_channel_id = guildSchema.systemChannelId,
			system_channel_flags = guildSchema.systemChannelFlags,
			rules_channel_id = guildSchema.rulesChannelId,
			public_update_channel_id = guildSchema.publicUpdateChannelId,
			preferred_locale = guildSchema.preferredLocale,
			features = guildSchema.features,
			description = guildSchema.description,
			premium_progress_bar_enabled = guildSchema.premiumProgressBarEnabled,
			safety_alerts_channel_id = guildSchema.safetyAlertsChanneId
		}):await()
	end)
end

function DiscordGuild.Prototype.deleteAsync(self: DiscordGuild)
	return Future.try(function()
		return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotDeleteGuild, self.id)):await()
	end)
end

function DiscordGuild.Prototype.getChannelsAsync(self: DiscordGuild)
	return Future.try(function()
		local rawChannelDatas = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetGuildChannels, self.id)):await()

		for index, value in rawChannelDatas do
			rawChannelDatas[index] = DiscordChannel.new(self.discordClient, value)
		end

		return rawChannelDatas
	end)
end

function DiscordGuild.Prototype.getMemberAsync(self: DiscordGuild, userId: string)
	return Future.try(function()
		local discordMember = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetGuildMember, self.id, userId)):await()

		return DiscordGuildMember.new(self.discordClient, userId, self.id, discordMember)
	end)
end

function DiscordGuild.Prototype.fetchGuildMembersAsync(self: DiscordGuild, limit: number, lastUserId: number?)
	return Future.try(function()
		local discordMembers = self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotGetGuildMembers, self.id, limit or 100, lastUserId or "0")):await()

		for index, memberObject in discordMembers do
			discordMembers[index] = DiscordGuildMember.new(self.discordClient, memberObject.user.id, self.id, memberObject)
		end

		return discordMembers
	end)
end

function DiscordGuild.Prototype.searchGuildMembersAsync(self: DiscordGuild, query: string, limit: number?)
	return Future.try(function()
		local discordMembers = self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.BotSearchGuildMembers, self.id, query, limit or "100")
		):await()

		for index, memberObject in discordMembers do
			discordMembers[index] = DiscordGuildMember.new(self.discordClient, memberObject.user.id, self.id, memberObject)
		end

		return discordMembers
	end)
end

function DiscordGuild.Prototype.listAutomoderationRulesAsync(self: DiscordGuild)
	return Future.try(function()
		local discordAutomoderationRules = self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.BotListAutomoderationRules, self.id)
		):await()

		for index, value in discordAutomoderationRules do
			discordAutomoderationRules[index] = DiscordAutomoderationRule.new(self.discordClient, value)
		end

		return discordAutomoderationRules
	end)
end

function DiscordGuild.Prototype.getAutomoderationRuleAsync(self: DiscordGuild, ruleId: string)
	return Future.try(function()
		local discordAutomoderationRule = self.discordClient.discordGateway:getAsync(
			string.format(DiscordEndpoints.BotGetAutomoderationRule, self.id)
		):await()

		return DiscordAutomoderationRule.new(self.discordClient, discordAutomoderationRule)
	end)
end

function DiscordGuild.Prototype.createAutomoderationRuleAsync(self: DiscordGuild, getAutomoderationRuleBuilder: DiscordAutomoderationRuleBuilder.DiscordAutomoderationRuleBuilder)
	return Future.try(function()
		local discordAutomoderationRule = self.discordClient.discordGateway:postAsync(
			string.format(DiscordEndpoints.BotCreateAutomoderationRule, self.id),
			getAutomoderationRuleBuilder:toJSONObject()
		):await()

		return DiscordAutomoderationRule.new(self.discordClient, discordAutomoderationRule)
	end)
end

function DiscordGuild.Interface.new(discordClient: any, guildData: {
	id: string,
	roles: { any },
	emojis: { any },
})
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordGuild, guildData.id, function()
		local guildStruct = {
			discordClient = discordClient,
			shardId = ((tonumber(guildData.id) :: number / 2^22) % discordClient.shardCount) + 1
		}

		return Construct(guildStruct, DiscordGuild.Prototype)
	end)

	if guildData.roles then
		for index, value in guildData.roles do
			guildData.roles[index] = DiscordGuildRole.new(discordClient, value)
		end
	end

	if guildData.emojis then
		for index, value in guildData.emojis do
			guildData.emojis[index] = DiscordEmoji.new(discordClient, value)
		end
	end

	for index, value in guildData do
		self[index] = value
	end

	return self
end

export type DiscordGuild = typeof(DiscordGuild.Prototype) & {
	discordClient: any,
	shardId: number,

	id: string,

	roles: { DiscordGuildRole.DiscordGuildRole },
	emojis: { DiscordEmoji.DiscordEmoji },
}

export type DiscordGuildSchema = {
	name: string,
	region: string?,
	verificationLevel: number,
	defaultMessageNotifications: number,
	explicitContentFilter: number,
	afkChannelId: string,
	afkTimeout: number,
	-- icon,
	ownerId: string,
	-- splash,
	-- discoverySplash,
	-- banner,
	systemChannelId: string,
	systemChannelFlags: number,
	rulesChannelId: string,
	publicUpdateChannelId: string,
	preferredLocale: string,
	features: { string },
	description: string,
	premiumProgressBarEnabled: boolean,
	safetyAlertsChanneId: string
}

return DiscordGuild.Interface