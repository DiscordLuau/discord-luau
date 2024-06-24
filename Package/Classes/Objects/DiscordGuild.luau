local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")

local Resolvable = require("@Network/Resolvable")

local GuildWidget = require("@Objects/GuildWidget")
local GuildOnboarding = require("@Objects/GuildOnboarding")
local GuildWelcomeScreen = require("@Objects/GuildWelcomeScreen")
local GuildPreview = require("@Objects/GuildPreview")
local DiscordEmoji = require("@Objects/DiscordEmoji")
local DiscordGuildRole = require("@Objects/DiscordGuildRole")
local DiscordChannel = require("@Objects/DiscordChannel")
local DiscordUser = require("@Objects/DiscordUser")
local DiscordGuildBan = require("@Objects/DiscordGuildBan")
local DiscordGuildMember = require("@Objects/DiscordGuildMember")
local DiscordAutomoderationRule = require("@Objects/DiscordAutomoderationRule")
local DiscordInvite = require("@Objects/DiscordInvite")
local DiscordIntegration = require("@Objects/DiscordIntegration")
local DiscordSticker = require("@Objects/DiscordSticker")

local CommandBuilder = require("@Builders/CommandBuilder")
local AutomoderationRuleBuilder = require("@Builders/AutomoderationRuleBuilder")
local GuildBuilder = require("@Builders/GuildBuilder")
local ChannelBuilder = require("@Builders/ChannelBuilder")
local MemberBuilder = require("@Builders/MemberBuilder")
local GuildRoleBuilder = require("@Builders/GuildRoleBuilder")
local WelcomeScreenBuilder = require("@Builders/WelcomeScreenBuilder")
local OnboardingBuilder = require("@Builders/OnboardingBuilder")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

local CacheType = require("@Enums/CacheType")
local ResolvableType = require("@Enums/ResolvableType")

--[=[
	@class Objects.DiscordGuild

	The `DiscordGuild` class represents a Discord guild (server) and provides methods to interact with and manage the guild.
]=]

--[=[
	@prop shardId number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop id string
	@within Objects.DiscordGuild
]=]

--[=[
	@prop name string
	@within Objects.DiscordGuild
]=]

--[=[
	@prop icon string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop iconHash string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop splash string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop discoverySplash string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop owner boolean
	@within Objects.DiscordGuild
]=]

--[=[
	@prop ownerId string
	@within Objects.DiscordGuild
]=]

--[=[
	@prop permissions number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop afkChannelId string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop afkTimeout number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop widgetEnabled boolean
	@within Objects.DiscordGuild
]=]

--[=[
	@prop widgetChannelId string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop verificationLevel number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop defaultMessageNotifications number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop explicitContentFilter number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop roles { Objects.DiscordGuildRole }
	@within Objects.DiscordGuild
]=]

--[=[
	@prop emojis { Objects.DiscordEmoji }
	@within Objects.DiscordGuild
]=]

--[=[
	@prop features { string }
	@within Objects.DiscordGuild
]=]

--[=[
	@prop mfaLevel number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop applicationId string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop systemChannelId string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop systemChannelFlags number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop rulesChannelId string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop maxPresences number?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop maxMembers number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop vanityUrlCode string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop description string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop banner string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop premiumTier number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop premiumSubscriptionCount number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop preferredLocale string
	@within Objects.DiscordGuild
]=]

--[=[
	@prop publicUpdatesChannelId string?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop maxVideoChannelUsers number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop maxStageVideoChannelUsers number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop approximateMemberCount number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop approximatePresenceCount number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop welcomeScreen Objects.GuildWelcomeScreen?
	@within Objects.DiscordGuild
]=]

--[=[
	@prop nsfwLevel number
	@within Objects.DiscordGuild
]=]

--[=[
	@prop stickers { Objects.DiscordSticker }
	@within Objects.DiscordGuild
]=]

--[=[
	@prop premiumProgressBarEnabled boolean
	@within Objects.DiscordGuild
]=]

--[=[
	@prop safetyAlertsChannelId string?
	@within Objects.DiscordGuild
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
	@return Vendor.Future
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
	@return Vendor.Future
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
	@return Vendor.Future
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
	@return Vendor.Future
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
	@return Vendor.Future
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
			guildChannels[key] = DiscordChannel.from(self.discordClient, channelData)
		end

		return guildChannels
	end)
end

--[=[
	Sets multiple slash commands in the guild asynchronously.

	@method setSlashCommandsAsync
	@param commands {CommandBuilder} -- An array of command builder objects.
	@return Vendor.Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.setSlashCommandsAsync(self: DiscordGuild, commands: { CommandBuilder.CommandBuilder })
	return Future.try(function()
		local commandObjects = {}

		for index, commandBuilder in commands do
			commandObjects[index] = commandBuilder:toPayloadObject():resolve()
		end

		return self.discordClient.discordGateway
			:putAsync(
				string.format(
					DiscordEndpoints.OverwriteGuildApplicationCommands,
					self.discordClient.discordApplication.id,
					self.id
				),
				Resolvable.new(ResolvableType.JSON, commandObjects)
			)
			:await()
	end)
end

--[=[
	Gets the audit logs of the guild asynchronously.

	@method getGuildAuditLogs
	@return Vendor.Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildAuditLogs(self: DiscordGuild)
	return Future.try(function()
		local guildAuditLogs = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.GetGuildAuditLogs, self.id))
			:await()

		for index, channelObject in guildAuditLogs.threads do
			guildAuditLogs.threads[index] = DiscordChannel.from(self.discordClient, channelObject)
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
	@param guildBuilder Builders.GuildBuilder
	@return Vendor.Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.modifyAsync(self: DiscordGuild, guildBuilder: GuildBuilder.GuildBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(string.format(DiscordEndpoints.BotModifyGuild, self.id), guildBuilder:toPayloadObject())
			:await()
	end)
end

--[=[
	Modifies the current member of the discord guild

	@method modifyCurrentMemberAsync
	@param memberBuilder Builders.MemberBuilder
	@return Vendor.Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.modifyCurrentMemberAsync(self: DiscordGuild, memberBuilder: MemberBuilder.MemberBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(DiscordEndpoints.BotModifyCurrentMemberGuild, self.id),
				memberBuilder:toPayloadObject()
			)
			:await()
	end)
end

--[=[
	Deletes the guild asynchronously.

	@method deleteAsync
	@return Vendor.Future
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
	@return Vendor.Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getChannelsAsync(self: DiscordGuild)
	return Future.try(function()
		local rawChannelDatas = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildChannels, self.id))
			:await()

		for index, value in rawChannelDatas do
			rawChannelDatas[index] = DiscordChannel.from(self.discordClient, value)
		end

		return rawChannelDatas
	end)
end

--[=[
	Gets a specific member of the guild asynchronously.

	@method getMemberAsync
	@param userId string -- The ID of the user to retrieve.
	@return Vendor.Future
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
	@return Vendor.Future
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
	@return Vendor.Future
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
	@return Vendor.Future
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
	@return Vendor.Future
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
	@return Vendor.Future
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
	Get the preview of the current Guild

	@method getPreviewAsync
	@return Vendor.Future<Objects.GuildPreview>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getPreviewAsync(self: DiscordGuild)
	return Future.try(function()
		local previewData = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildPreview, self.id))
			:await()

		return GuildPreview.new(self.discordClient, previewData)
	end)
end

--[=[
	Creates a Guild Channel under a Guild.

	@method createChannelAsync
	@param channelBuilder Builders.ChannelBuilder
	@return Vendor.Future<Objects.DiscordChannel>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.createChannelAsync(self: DiscordGuild, channelBuilder: ChannelBuilder.ChannelBuilder)
	return Future.try(function()
		local channelData = self.discordClient.discordGateway
			:postAsync(string.format(DiscordEndpoints.BotCreateGuildChannel, self.id), channelBuilder:toPayloadObject())
			:await()

		return DiscordChannel.from(self.discordClient, channelData)
	end)
end

--[=[
	Fetches all active guild threads.

	@method getActiveGuildThreads
	@return Vendor.Future<{ Objects.DiscordChannel }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getActiveGuildThreads(self: DiscordGuild)
	return Future.try(function()
		local threadDatas: { DiscordChannel.DiscordChannel } = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetAllActiveGuildThreads, self.id))
			:await()

		for key, value in threadDatas do
			threadDatas[key] = DiscordChannel.from(self.discordClient, value)
		end

		return threadDatas
	end)
end

--[=[
	Adds a discordian to a guild.

	@method addMemberAsync
	@param userId string
	@param accessToken string
	@return Vendor.Future<{ Objects.DiscordChannel }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.addMemberAsync(self: DiscordGuild, userId: string, accessToken: string)
	return Future.try(function()
		local guildMember = self.discordClient.discordGateway
			:putAsync(
				string.format(DiscordEndpoints.BotAddGuildMember, self.id, userId),
				Resolvable.new(ResolvableType.JSON, {
					access_token = accessToken,
				})
			)
			:await()

		return DiscordGuildMember.new(self.discordClient, userId, self.id, guildMember)
	end)
end

--[=[
	Fetches an array of Guild Bans

	@method getGuildBansAsync
	@param limit number?
	@param before string?
	@param after string?
	@return Vendor.Future<{ Objects.DiscordGuildBan }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildBansAsync(self: DiscordGuild, limit: number?, before: string?, after: string?)
	return Future.try(function()
		local guildBans = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildBans, self.id, before or "", after or "", limit or 100))
			:await()

		for key, value in guildBans do
			guildBans[key] = DiscordGuildBan.new(self.discordClient, value)
		end

		return guildBans
	end)
end

--[=[
	Fetches the ban object for a specific user id

	@method getGuildBanAsync
	@param userId string
	@return Vendor.Future<Objects.DiscordGuildBan?>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildBanAsync(self: DiscordGuild, userId: string)
	return Future.try(function()
		local guildBan = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildBan, self.id, userId))
			:await()

		return DiscordGuildBan.new(self.discordClient, guildBan)
	end)
end

--[=[
	Bans up to 200 members asynchronously

	@method bulkGuildBanAsync
	@param userIds { string }
	@return Vendor.Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.bulkGuildBanAsync(self: DiscordGuild, userIds: { string })
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.BotBulkGuildBan, self.id),
				Resolvable.new(ResolvableType.JSON, userIds)
			)
			:await()
	end)
end

--[=[
	Allows you to get all roles within a guild.

	@method bulkGuildBanAsync
	@return Vendor.Future<{ Objects.DiscordGuildRole }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildRolesAsync(self: DiscordGuild)
	return Future.try(function()
		local guildRoles: { DiscordGuildRole.DiscordGuildRole } =
			self.discordClient.discordGateway:getAsync(string.format(DiscordEndpoints.BotBulkGuildBan, self.id)):await()

		for key, value in guildRoles do
			guildRoles[key] = DiscordGuildRole.new(self.discordClient, value)
		end

		return guildRoles
	end)
end

--[=[
	Allows you to get all roles within a guild.

	@method bulkGuildBanAsync
	@return Vendor.Future<{ Objects.DiscordGuildRole }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.createGuildRoleAsync(self: DiscordGuild, roleBuilder: GuildRoleBuilder.GuildRoleBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(string.format(DiscordEndpoints.BotCreateGuildRole, self.id), roleBuilder:toPayloadObject())
			:await()
	end)
end

--[=[
	Setst he guilds MFA level.

	@method setMFALevelAsync
	@param mfaLevel number
	@return Vendor.Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.setMFALevelAsync(self: DiscordGuild, mfaLevel: number)
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.BotModifyGuildMFALevel, self.id),
				Resolvable.new(ResolvableType.JSON, {
					level = mfaLevel,
				})
			)
			:await()
	end)
end

--[=[
	Fetches the prune count.

	@method getPruneCountAsync
	@param days number?
	@param includedRoles { string }?
	@return Vendor.Future<{ pruned: number }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getPruneCountAsync(self: DiscordGuild, days: number?, includedRoles: { string }?)
	return Future.try(function()
		return self.discordClient.discordGateway
			:getAsync(
				string.format(
					DiscordEndpoints.BotGetGuildPruneCount,
					self.id,
					days or 7,
					includedRoles and table.concat(includedRoles, ",") or ""
				)
			)
			:await() :: {
			pruned: number,
		}
	end)
end

--[=[
	Requests discord to prune the Discord guild.

	@method getPruneCountAsync
	@param days number?
	@param computePruneCount boolean?
	@param includeRoles { string }?
	@return Vendor.Future<{ pruned: number }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.beginPruneAsync(
	self: DiscordGuild,
	days: number?,
	computePruneCount: boolean?,
	includeRoles: { string }?
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:postAsync(
				string.format(DiscordEndpoints.BotBeginGuildPrune, self.id),
				Resolvable.new(ResolvableType.JSON, {
					days = days,
					compute_prune_count = computePruneCount,
					include_roles = includeRoles,
				})
			)
			:await() :: {
			pruned: number?,
		}
	end)
end

--[=[
	Fetches the available voice regions for the guild.

	@method getGuildVoiceRegionsAsync
	@return Vendor.Future<{ { id: string, name: string, optimal: boolean, deprecated: boolean, custom: boolean } }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildVoiceRegionsAsync(self: DiscordGuild)
	return Future.try(function()
		return self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildVoiceRegions, self.id))
			:await() :: { { id: string, name: string, optimal: boolean, deprecated: boolean, custom: boolean } }
	end)
end

--[=[
	Fetches all guild invite objects.

	@method getGuildInvitesAsync
	@return Vendor.Future<{ Objects.DiscordInvite }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildInvitesAsync(self: DiscordGuild)
	return Future.try(function()
		local guildInvites: { DiscordInvite.DiscordInvite } = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildInvites, self.id))
			:await()

		for key, value in guildInvites do
			guildInvites[key] = DiscordInvite.new(self.discordClient, value)
		end

		return guildInvites
	end)
end

--[=[
	Fetches all guild integrations

	@method getGuildIntegrationsAsync
	@return Vendor.Future<{ Objects.DiscordIntegration }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildIntegrationsAsync(self: DiscordGuild)
	return Future.try(function()
		local guildIntegrations: { DiscordIntegration.DiscordIntegration } = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildIntegrations, self.id))
			:await()

		for key, value in guildIntegrations do
			guildIntegrations[key] = DiscordIntegration.new(self.discordClient, self.id, value)
		end

		return guildIntegrations
	end)
end

--[=[
	Fetches the widget settings for the current guild.

	@method getGuildWidgetSettingsAsync
	@return Vendor.Future<{ enabled: boolean, cannelId: string }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildWidgetSettingsAsync(self: DiscordGuild)
	return Future.try(function()
		return self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildWidgetSettings, self.id))
			:await() :: {
			enabled: boolean,
			cannelId: string,
		}
	end)
end

--[=[
	Updates the widget settings for the current guild

	@method updateGuildWidgetSettingsAsync
	@param widgetEnabled boolean
	@param channelId string
	@return Vendor.Future<{ enabled: boolean, cannelId: string }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.updateGuildWidgetSettingsAsync(self: DiscordGuild, enabled: boolean, channelId: string?)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(DiscordEndpoints.BotModifyGuildWidgetSettings, self.id),
				Resolvable.new(ResolvableType.JSON, {
					enabled = enabled,
					channelId = channelId,
				})
			)
			:await() :: {
			enabled: boolean,
			cannelId: string,
		}
	end)
end

--[=[
	Gets the guild widget for this guild.

	@method getGuldWidgetAsync
	@return Vendor.Future<Objects.GuildWidget>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildWidgetAsync(self: DiscordGuild)
	return Future.try(function()
		local widgetObject = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildWidget, self.id))
			:await()

		return GuildWidget.new(self.discordClient, widgetObject)
	end)
end

--[=[
	Gets the vanity url for this guild.

	@method getGuildVanityUrlAsync
	@return Vendor.Future<{ code: string, uses: number }>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildVanityUrlAsync(self: DiscordGuild)
	return Future.try(function()
		return self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildVanityURL, self.id))
			:await() :: {
			code: string,
			uses: number,
		}
	end)
end

--[=[
	Gets the guild welcome screen for this guild.

	@method getGuildWelcomeScreenAsync
	@return Vendor.Future<Objects.GuildWelcomeScreen>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildWelcomeScreenAsync(self: DiscordGuild)
	return Future.try(function()
		local welcomeScreen = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildWelcomeScreen, self.id))
			:await()

		return GuildWelcomeScreen.new(self.discordClient, welcomeScreen)
	end)
end

--[=[
	Gets the binary PNG image for a server widget

	@method getGuildWidgetImageAsync
	@param style 'shield' | 'banner1' | 'banner2' | 'banner3' | 'banner4'
	@return Vendor.Future<string>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildWidgetImageAsync(
	self: DiscordGuild,
	style: ("shield" | "banner1" | "banner2" | "banner3" | "banner4")?
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetWidgetImage, self.id, style or "shield"))
			:await()
	end)
end

--[=[
	Updates the guild welcome screen for this guild.

	@method modifyGuildWelcomeScreenAsync
	@param welcomeScreenBuilder Builders.WelcomeScreenBuilder
	@return Vendor.Future
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.modifyGuildWelcomeScreenAsync(
	self: DiscordGuild,
	welcomeScreenBuilder: WelcomeScreenBuilder.WelcomeScreenBuilder
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(
				string.format(DiscordEndpoints.BotModifyGuildWelcomeScreen, self.id),
				welcomeScreenBuilder:toPayloadObject()
			)
			:await()
	end)
end

--[=[
	Gets the onboarding for this guild

	@method getGuldOnboardingAsync
	@return Vendor.Future<Objects.GuildOnboarding>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.getGuildOnboardingAsync(self: DiscordGuild)
	return Future.try(function()
		local onboarding = self.discordClient.discordGateway
			:getAsync(string.format(DiscordEndpoints.BotGetGuildOnboarding, self.id))
			:await()

		return GuildOnboarding.new(self.discordClient, onboarding)
	end)
end

--[=[
	Updates the onboarding for this guild

	@method getGuldOnboardingAsync
	@param guildOnboardingBuilder Builders.OnboardingBuilder
	@return Vendor.Future<Objects.GuildOnboarding>
	@within Objects.DiscordGuild
]=]
function DiscordGuild.Prototype.modifyGuildOnboardingAsync(
	self: DiscordGuild,
	guildOnboardingBuilder: OnboardingBuilder.OnboardingBuilder
)
	return Future.try(function()
		return self.discordClient.discordGateway
			:putAsync(
				string.format(DiscordEndpoints.BotModifyGuildOnboarding, self.id),
				guildOnboardingBuilder:toPayloadObject()
			)
			:await()
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
	name: string,
	icon: string?,
	iconHash: string?,
	splash: string?,
	discoverySplash: string?,
	owner: boolean,
	ownerId: string,
	permissions: number,
	afkChannelId: string?,
	afkTimeout: number,
	widgetEnabled: boolean,
	widgetChannelId: string?,
	verificationLevel: number,
	defaultMessageNotifications: number,
	explicitContentFilter: number,
	roles: { DiscordGuildRole.DiscordGuildRole },
	emojis: { DiscordEmoji.DiscordEmoji },
	features: { string },
	mfaLevel: number,
	applicationId: string?,
	systemChannelId: string?,
	systemChannelFlags: number,
	rulesChannelId: string?,
	maxPresences: number?,
	maxMembers: number,
	vanityUrlCode: string?,
	description: string?,
	banner: string?,
	premiumTier: number,
	premiumSubscriptionCount: number,
	preferredLocale: string,
	publicUpdatesChannelId: string?,
	maxVideoChannelUsers: number,
	maxStageVideoChannelUsers: number,
	approximateMemberCount: number,
	approximatePresenceCount: number,
	welcomeScreen: GuildWelcomeScreen.GuildWelcomeScreen?,
	nsfwLevel: number,
	stickers: { DiscordSticker.DiscordSticker },
	premiumProgressBarEnabled: boolean,
	safetyAlertsChannelId: string?,
}

return DiscordGuild.Interface
