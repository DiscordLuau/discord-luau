local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local CommandBuilder = require("../Builders/CommandBuilder")
local AutomoderationRuleBuilder = require("../Builders/AutomoderationRuleBuilder")

local DiscordEmoji = require("DiscordEmoji")
local DiscordGuildRole = require("DiscordGuildRole")
local DiscordChannel = require("DiscordChannel")
local DiscordUser = require("DiscordUser")

local DiscordGuildMember = require("DiscordGuildMember")

local DiscordAutomoderationRule = require("DiscordAutomoderationRule")

local Future = require("../../Vendor/Future")

local Resolvable = require("../Network/Resolvable")
local ResolvableType = require("../../Enums/ResolveableType")

--[=[
	@class Objects.DiscordGuild

	The `DiscordGuild` class represents a Discord guild (server) and provides methods to interact with and manage the guild.
]=]
local DiscordGuild = {}

DiscordGuild.Prototype = {}
DiscordGuild.Interface = {}

--[=[
	@prop type string
	@within Objects.DiscordGuild
	@readonly

	The type of the DiscordGuild. Default is "DiscordGuild".
]=]
DiscordGuild.Prototype.type = "DiscordGuild"

--[=[
	Creates a new slash command in the guild asynchronously.

	@method createSlashCommandAsync
	@param command CommandBuilder -- The command builder object.
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.createSlashCommandAsync(self: DiscordGuild, command: CommandBuilder.CommandBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(
				string.format(
					DiscordEndpoints.CreateGuildApplicationCommand,
					self.discordClient.discordApplication.id,
					self.id
				),
				command:toPayloadObject()
			)
			:await()
	end)
end

--[=[
	Deletes a slash command in the guild asynchronously.

	@method deleteSlashCommandAsync
	@param commandId string -- The ID of the command to delete.
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.deleteSlashCommandAsync(self: DiscordGuild, commandId: string)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(
				string.format(
					DiscordEndpoints.DeleteGuildApplicationCommand,
					self.discordClient.discordApplication.id,
					self.id,
					commandId
				)
			)
			:await()
	end)
end

--[=[
	Edits a slash command in the guild asynchronously.

	@method editSlashCommandAsync
	@param commandId string -- The ID of the command to edit.
	@param command CommandBuilder -- The command builder object with updated information.
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.editSlashCommandAsync(
	self: DiscordGuild,
	commandId: string,
	command: CommandBuilder.CommandBuilder
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(
					DiscordEndpoints.EditGuildApplicationCommand,
					self.discordClient.discordApplication.id,
					self.id,
					commandId
				),
				command:toPayloadObject()
			)
			:await()
	end)
end

--[=[
	Fetches all slash commands in the guild asynchronously.

	@method fetchSlashCommandsAsync
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.fetchSlashCommandsAsync(self: DiscordGuild)
	return Future.try(function()
		return self.discordClient.discordGateway
			:getAsync(
				string.format(
					DiscordEndpoints.GetGuildApplicationCommands,
					self.discordClient.discordApplication.id,
					self.id
				)
			)
			:await()
	end)
end

--[=[
	Fetches all channels in the guild asynchronously.

	@method fetchGuildChannels
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.fetchGuildChannels(self: DiscordGuild)
	return Future.try(function()
		local guildChannels = self.discordClient.discordGateway
			:getAsync(
				string.format(DiscordEndpoints.BotGetGuildChannels, self.discordClient.discordApplication.id, self.id)
			)
			:await()

		for key, channelData in guildChannels do
			guildChannels[key] = DiscordChannel.new(self.discordClient, channelData)
		end

		return guildChannels
	end)
end

--[=[
	Sets multiple slash commands in the guild asynchronously.

	@method setSlashCommandsAsync
	@param commands {CommandBuilder} -- An array of command builder objects.
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.setSlashCommandsAsync(self: DiscordGuild, commands: { CommandBuilder.CommandBuilder })
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

		for commandId: string, command: CommandBuilder.CommandBuilder in commandsToUpdate do
			self:editSlashCommandAsync(commandId, command):await()
		end

		for _, command: CommandBuilder.CommandBuilder in commandsToCreate do
			self:createSlashCommandAsync(command):await()
		end
	end)
end

--[=[
	Gets the audit logs of the guild asynchronously.

	@method getGuildAuditLogs
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildAuditLogs(self: DiscordGuild)
	return Future.try(function()
		local guildAuditLogs = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.GetGuildAuditLogs, self.id))
			:await()

		for index, channelObject in guildAuditLogs.threads do
			guildAuditLogs.threads[index] = DiscordChannel.new(self.discordClient, channelObject)
		end

		for index, userObject in guildAuditLogs.users do
			guildAuditLogs.users[index] = DiscordUser.new(self.discordClient, userObject)
		end

		return guildAuditLogs
	end)
end

--[=[
	Modifies the guild settings asynchronously.

	@method modifyAsync
	@param guildSchema DiscordGuildSchema -- The schema containing the new settings for the guild.
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.modifyAsync(self: DiscordGuild, guildSchema: DiscordGuildSchema)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(DiscordEndpoints.BotModifyGuild, self.id),
				Resolvable.new(ResolvableType.JSON, { -- todo: throw GuildSchema into a guild builder
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
					safety_alerts_channel_id = guildSchema.safetyAlertsChannelId,
				})
			)
			:await()
	end)
end

--[=[
	Deletes the guild asynchronously.

	@method deleteAsync
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.deleteAsync(self: DiscordGuild)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotDeleteGuild, self.id))
			:await()
	end)
end

--[=[
	Gets all channels in the guild asynchronously.

	@method getChannelsAsync
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getChannelsAsync(self: DiscordGuild)
	return Future.try(function()
		local rawChannelDatas = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildChannels, self.id))
			:await()

		for index, value in rawChannelDatas do
			rawChannelDatas[index] = DiscordChannel.new(self.discordClient, value)
		end

		return rawChannelDatas
	end)
end

--[=[
	Gets a specific member of the guild asynchronously.

	@method getMemberAsync
	@param userId string -- The ID of the user to retrieve.
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getMemberAsync(self: DiscordGuild, userId: string)
	return Future.try(function()
		local discordMember = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildMember, self.id, userId))
			:await()

		return DiscordGuildMember.new(self.discordClient, userId, self.id, discordMember)
	end)
end

--[=[
	Fetches members of the guild asynchronously.

	@method fetchGuildMembersAsync
	@param limit number -- The maximum number of members to retrieve.
	@param lastUserId number? -- The ID of the last user retrieved (for pagination).
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.fetchGuildMembersAsync(self: DiscordGuild, limit: number, lastUserId: number?)
	return Future.try(function()
		local discordMembers = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildMembers, self.id, limit or 100, lastUserId or "0"))
			:await()

		for index, memberObject in discordMembers do
			discordMembers[index] =
				DiscordGuildMember.new(self.discordClient, memberObject.user.id, self.id, memberObject)
		end

		return discordMembers
	end)
end

--[=[
	Searches for members in the guild asynchronously.

	@method searchGuildMembersAsync
	@param query string -- The search query.
	@param limit number? -- The maximum number of members to retrieve.
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.searchGuildMembersAsync(self: DiscordGuild, query: string, limit: number?)
	return Future.try(function()
		local discordMembers = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotSearchGuildMembers, self.id, query, limit or "100"))
			:await()

		for index, memberObject in discordMembers do
			discordMembers[index] =
				DiscordGuildMember.new(self.discordClient, memberObject.user.id, self.id, memberObject)
		end

		return discordMembers
	end)
end

--[=[
	Lists all automoderation rules in the guild asynchronously.

	@method listAutomoderationRulesAsync
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.listAutomoderationRulesAsync(self: DiscordGuild)
	return Future.try(function()
		local discordAutomoderationRules = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotListAutomoderationRules, self.id))
			:await()

		for index, value in discordAutomoderationRules do
			discordAutomoderationRules[index] = DiscordAutomoderationRule.new(self.discordClient, value)
		end

		return discordAutomoderationRules
	end)
end

--[=[
	Gets a specific automoderation rule in the guild asynchronously.

	@method getAutomoderationRuleAsync
	@param ruleId string -- The ID of the rule to retrieve.
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getAutomoderationRuleAsync(self: DiscordGuild, ruleId: string)
	return Future.try(function()
		local discordAutomoderationRule = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetAutomoderationRule, self.id, ruleId))
			:await()

		return DiscordAutomoderationRule.new(self.discordClient, discordAutomoderationRule)
	end)
end

--[=[
	Creates an automoderation rule in the guild asynchronously.

	@method createAutomoderationRuleAsync
	@param getAutomoderationRuleBuilder AutomoderationRuleBuilder -- The rule builder object.
	@return Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.createAutomoderationRuleAsync(
	self: DiscordGuild,
	getAutomoderationRuleBuilder: AutomoderationRuleBuilder.AutomoderationRuleBuilder
)
	return Future.try(function()
		local discordAutomoderationRule = self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.BotCreateAutomoderationRule, self.id),
				getAutomoderationRuleBuilder:toPayloadObject()
			)
			:await()

		return DiscordAutomoderationRule.new(self.discordClient, discordAutomoderationRule)
	end)
end

--[=[
	Creates a new DiscordGuild instance.

	@function new
	@param discordClient any -- The Discord client instance.
	@param guildData table -- The raw data for the guild.
	@return DiscordGuild -- The newly created DiscordGuild instance.
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Interface.new(
	discordClient: any,
	guildData: {
		id: string,
		roles: { any },
		emojis: { any },
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordGuild, guildData.id, function()
		local guildStruct = {
			discordClient = discordClient,
			shardId = ((tonumber(guildData.id) :: number / 2 ^ 22) % discordClient.shardCount) + 1,
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
	ownerId: string,
	systemChannelId: string,
	systemChannelFlags: number,
	rulesChannelId: string,
	publicUpdateChannelId: string,
	preferredLocale: string,
	features: { string },
	description: string,
	premiumProgressBarEnabled: boolean,
	safetyAlertsChannelId: string,
}

return DiscordGuild.Interface
