--[[
	Implementation of the Discord Guild class in Luau

	https://discord.com/developers/docs/resources/guild#guild-object
]]

local future = require("@vendor/future")

local apiTypes = require("@api-types/apiTypes")
local guildTypes = require("@api-types/guild")
local channelTypes = require("@api-types/channel")

local state = require("@classes/state")
local emoji = require("@classes/emoji")
local sticker = require("@classes/sticker")
local role = require("@classes/guild/role")
local welcomeScreen = require("@classes/guild/welcomeScreen")
local preview = require("@classes/guild/preview")
local member = require("@classes/guild/member")
local ban = require("@classes/guild/ban")
local voiceRegion = require("@classes/guild/voiceRegion")
local invite = require("@classes/guild/invite")

local guildAnnouncement = require("@classes/channels/types/guildAnnouncement")
local guildCategory = require("@classes/channels/types/guildCategory")
local guildDirectory = require("@classes/channels/types/guildDirectory")
local guildStageVoice = require("@classes/channels/types/guildStageVoice")
local guildText = require("@classes/channels/types/guildText")
local guildVoice = require("@classes/channels/types/guildVoice")

local announcementThread = require("@classes/channels/threads/announcement")
local privateThread = require("@classes/channels/threads/private")
local publicThread = require("@classes/channels/threads/public")

local guildBuilder = require("@builders/guild/guild")
local channelBuilder = require("@builders/channel")

local systemChannelBitflag = require("@classes/bitflags/systemChannel")

local guildRest = require("@rest/guild")
local commandsRest = require("@rest/commands")

local interactionBuilder = require("@builders/interaction/interaction")
local roleBuilder = require("@builders/guild/role")

local commandObject = require("@classes/application/command/command")

local constructChannelFromData = require("@utils/constructChannelFromData")

local Guild = {}

Guild.Interface = {}
Guild.Prototype = {}

--[[
	Creates a guild Slash command for the application
]]
function Guild.Prototype.createSlashCommandAsync(
	self: Guild,
	slashCommand: interactionBuilder.JSON
): future.Future<commandObject.Command>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = commandsRest
			.createGuildApplicationCommandAsync(request, self.state.applicationId, self.id, slashCommand)
			:await()

		assert(status == "Fulfilled", tostring(response))

		return commandObject.new(response)
	end)
end

--[[
	Delete an existing guild application command.
]]
function Guild.Prototype.deleteSlashCommandAsync(self: Guild, slashCommandId: apiTypes.Snowflake): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = commandsRest
			.deleteGuildApplicationCommandAsync(request, self.state.applicationId, self.id, slashCommandId)
			:await()

		assert(status == "Fulfilled", tostring(response))
	end)
end

--[[
	Edit an existing guild application command.
]]
function Guild.Prototype.editSlashCommandAsync(
	self: Guild,
	slashCommandId: apiTypes.Snowflake,
	slashCommand: interactionBuilder.JSON
): future.Future<commandObject.Command>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = commandsRest
			.editGuildApplicationCommandAsync(request, self.state.applicationId, self.id, slashCommandId, slashCommand)
			:await()

		assert(status == "Fulfilled", tostring(response))

		return commandObject.new(response)
	end)
end

--[[
	Get a list of guild application commands.
]]
function Guild.Prototype.getSlashCommandsAsync(
	self: Guild,
	withLocalizations: boolean?
): future.Future<{ commandObject.Command }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = commandsRest
			.getGuildApplicationCommandsAsync(request, self.state.applicationId, self.id, {
				withLocalizations = withLocalizations,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local commands = {}

		for _, commandData in response do
			table.insert(commands, commandObject.new(commandData))
		end

		return commands
	end)
end

--[[
	Overwrite all guild application commands. This will skip over commands that are the same as the current commands,
	and will not remove any existing commands.
]]
function Guild.Prototype.overwriteSlashCommandsAsync(
	self: Guild,
	slashCommands: { interactionBuilder.JSON }
): future.Future<{ commandObject.Command }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local status, response = commandsRest
			.bulkOverwriteGuildApplicationCommandsAsync(request, self.state.applicationId, self.id, slashCommands :: any)
			:await()

		assert(status == "Fulfilled", tostring(response))

		local commands = {}

		for _, commandData in response do
			table.insert(commands, commandObject.new(commandData))
		end

		return commands
	end)
end

--[[
	Returns the guild preview object for the given id. If the user is not in the guild, then the guild must be
	discoverable.
]]
function Guild.Prototype.fetchGuildPreviewAsync(self: Guild): future.Future<preview.Preview>
	return future.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local status, response = guildRest.getGuildPreviewAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		return preview.new(response)
	end)
end

--[[
	Modify a guild's settings. Requires the MANAGE_GUILD permission. Returns the updated guild object on success.
	Fires a Guild Update Gateway event.
]]
function Guild.Prototype.modifyGuildAsync(self: Guild, json: guildBuilder.JSON, reason: string?): future.Future<Guild>
	return future.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local status, response = guildRest.modifyGuildAsync(request, self.id, json, reason):await()

		assert(status == "Fulfilled", tostring(response))

		self:sync(response)

		return self
	end)
end

--[[
	Delete a guild permanently. User must be owner. Returns 204 No Content on success.Fires a Guild Delete Gateway
	event.
]]
function Guild.Prototype.deleteGuildAsync(self: Guild): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.deleteGuildAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))
	end)
end

--[[
	Returns a list of guild channel objects. Does not include threads.

	Typed as unknown because the API returns a variety of channel types, and luau's type system is not currently
	capable of handling this.

	Please use explicit functions for specific channel types, for example: getTextChannelsAsync, getVoiceChannelsAsync, etc.
]]
function Guild.Prototype.getChannelsAsync(self: Guild): future.Future<{ type: channelTypes.ChannelType }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.getGuildChannelsAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local channels: { unknown } = {}

		for _, channelData in next, response do
			table.insert(channels, constructChannelFromData(channelData))
		end

		return channels
	end)
end

--[[
	Returns a list of guild text channel objects.
]]
function Guild.Prototype.getTextChannelsAsync(self: Guild): future.Future<{ guildText.GuildText }>
	return future.new(function()
		local channels = self:getChannelsAsync():expect(`:getChannelsAsync failed!`)
		local textChannels: { guildText.GuildText } = {}

		for _, channel in next, channels do
			if channel.type ~= "GuildText" then
				continue
			end

			table.insert(textChannels, channel :: guildText.GuildText)
		end

		return textChannels
	end)
end

--[[
	Returns a list of guild voice channel objects.
]]
function Guild.Prototype.getVoiceChannelsAsync(self: Guild): future.Future<{ guildVoice.GuildVoice }>
	return future.new(function()
		local channels = self:getChannelsAsync():expect(`:getChannelsAsync failed!`)
		local voiceChannels: { guildVoice.GuildVoice } = {}

		for _, channel in next, channels do
			if channel.type ~= "GuildVoice" then
				continue
			end

			table.insert(voiceChannels, channel :: guildVoice.GuildVoice)
		end

		return voiceChannels
	end)
end

--[[
	Returns a list of guild category channel objects.
]]
function Guild.Prototype.getCategoryChannelsAsync(self: Guild): future.Future<{ guildText.GuildText }>
	return future.new(function()
		local channels = self:getChannelsAsync():expect(`:getChannelsAsync failed!`)
		local categoryChannels: { guildCategory.GuildCategory } = {}

		for _, channel in next, channels do
			if channel.type ~= "GuildCategory" then
				continue
			end

			table.insert(categoryChannels, channel :: guildCategory.GuildCategory)
		end

		return categoryChannels
	end)
end

--[[
	Returns a list of guild announcement channel objects.
]]
function Guild.Prototype.getAnnouncementChannelsAsync(
	self: Guild
): future.Future<{ guildAnnouncement.GuildAnnouncement }>
	return future.new(function()
		local channels = self:getChannelsAsync():expect(`:getChannelsAsync failed!`)
		local announcementChannels: { guildAnnouncement.GuildAnnouncement } = {}

		for _, channel in next, channels do
			if channel.type ~= "GuildCategory" then
				continue
			end

			table.insert(announcementChannels, channel :: guildAnnouncement.GuildAnnouncement)
		end

		return announcementChannels
	end)
end

--[[
	Returns a list of guild stage voice channel objects.
]]
function Guild.Prototype.getStageVoiceChannelsAsync(self: Guild): future.Future<{ guildStageVoice.GuildStageVoice }>
	return future.new(function()
		local channels = self:getChannelsAsync():expect(`:getChannelsAsync failed!`)
		local stageVoiceChannels: { guildStageVoice.GuildStageVoice } = {}

		for _, channel in next, channels do
			if channel.type ~= "GuildStageVoice" then
				continue
			end

			table.insert(stageVoiceChannels, channel :: guildStageVoice.GuildStageVoice)
		end

		return stageVoiceChannels
	end)
end

--[[
	Returns a list of guild directory channel objects.
]]
function Guild.Prototype.getDirectoryChannelsAsync(self: Guild): future.Future<{ guildDirectory.GuildDirectory }>
	return future.new(function()
		local channels = self:getChannelsAsync():expect(`:getChannelsAsync failed!`)
		local directoryChannels: { guildDirectory.GuildDirectory } = {}

		for _, channel in next, channels do
			if channel.type ~= "GuildDirectory" then
				continue
			end

			table.insert(directoryChannels, channel :: guildDirectory.GuildDirectory)
		end

		return directoryChannels
	end)
end

--[[
	Create a new channel object for the guild. Requires the MANAGE_CHANNELS permission. If setting permission
	overwrites, only permissions your bot has in the guild can be allowed/denied.
	
	Setting MANAGE_ROLES permission in channels is only possible for guild administrators.
	
	Returns the new channel object on success.
	
	Fires a Channel Create Gateway event.
]]
function Guild.Prototype.createChannelAsync<T>(
	self: Guild,
	json: channelBuilder.JSON,
	reason: string?
): future.Future<{ T }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.createGuildChannelAsync(request, self.id, json, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return constructChannelFromData(response)
	end)
end

--[[
	Returns all active threads in the guild, including public and private threads.
	Threads are ordered by their id, in descending order.

	Typed as unknown because the API returns a variety of channel types, and luau's type system is not currently
	capable of handling this.

	Please use explicit functions for specific channel types, for example: getMediaThreadsAsync, getAnnouncementThreadsAsync, etc.
]]
function Guild.Prototype.getThreadsAsync(self: Guild): future.Future<{ type: channelTypes.ChannelType }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.listActiveGuildThreadsAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local channels: { unknown } = {}

		for _, channelData in next, response.threads do
			table.insert(channels, constructChannelFromData(channelData))
		end

		return channels
	end)
end

--[[
	Returns a list of guild announcement thread objects.
]]
function Guild.Prototype.getAnnouncementThreadsAsync(self: Guild): future.Future<{ announcementThread.Announcement }>
	return future.new(function()
		local channels = self:getThreadsAsync():expect(`:getThreadsAsync failed!`)
		local announcementThreads: { announcementThread.Announcement } = {}

		for _, channel in next, channels do
			if channel.type ~= "AnnouncementThread" then
				continue
			end

			table.insert(announcementThreads, channel :: announcementThread.Announcement)
		end

		return announcementThreads
	end)
end

--[[
	Returns a list of public guild thread objects.
]]
function Guild.Prototype.getPublicThreadsAsync(self: Guild): future.Future<{ publicThread.Public }>
	return future.new(function()
		local channels = self:getThreadsAsync():expect(`:getThreadsAsync failed!`)
		local publicThreads: { publicThread.Public } = {}

		for _, channel in next, channels do
			if channel.type ~= "PublicThread" then
				continue
			end

			table.insert(publicThreads, channel :: publicThread.Public)
		end

		return publicThreads
	end)
end

--[[
	Returns a list of private guild thread objects.
]]
function Guild.Prototype.getPrivateThreadsAsync(self: Guild): future.Future<{ privateThread.Private }>
	return future.new(function()
		local channels = self:getThreadsAsync():expect(`:getThreadsAsync failed!`)
		local privateThreads: { privateThread.Private } = {}

		for _, channel in next, channels do
			if channel.type ~= "PrivateThread" then
				continue
			end

			table.insert(privateThreads, channel :: privateThread.Private)
		end

		return privateThreads
	end)
end

--[[
	Returns a list of private guild thread objects.
]]
function Guild.Prototype.getPrivateThreadsAsync(self: Guild): future.Future<{ privateThread.Private }>
	return future.new(function()
		local channels = self:getThreadsAsync():expect(`:getThreadsAsync failed!`)
		local privateThreads: { privateThread.Private } = {}

		for _, channel in next, channels do
			if channel.type ~= "GuildDirectory" then
				continue
			end

			table.insert(privateThreads, channel :: privateThread.Private)
		end

		return privateThreads
	end)
end

--[[
	Returns a guild member object for the specified user.
]]
function Guild.Prototype.getGuildMemberAsync(self: Guild, userId: string): future.Future<member.Member>
	return future.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local status, response = guildRest.getGuildMemberAsync(request, self.id, userId):await()

		assert(status == "Fulfilled", tostring(response))

		return member.new(response)
	end)
end

--[[
	Returns a list of guild member objects that are members of the guild.
]]
function Guild.Prototype.listGuildMembersAsync(
	self: Guild,
	lastSnowflake: string?,
	limit: number?
): future.Future<{ member.Member }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.listGuildMembersAsync(request, self.id, {
				limit = limit,
				after = lastSnowflake,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local members = {}

		for _, memberData in response do
			table.insert(members, member.new(memberData))
		end

		return members
	end)
end

--[[
	Returns a list of guild member objects whose username or nickname starts with a provided string.
]]
function Guild.Prototype.searchGuildMembersAsync(
	self: Guild,
	query: string,
	limit: number?
): future.Future<{ member.Member }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.searchGuildMembersAsync(request, self.id, {
				query = query,
				limit = limit,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local members = {}

		for _, memberData in response do
			table.insert(members, member.new(memberData))
		end

		return members
	end)
end

--[[
	Adds a user to the guild, provided you have a valid oauth2 access token for the user with the guilds.join scope.

	For guilds with Membership Screening enabled, this endpoint will default to adding new members as pending in the
	guild member object. Members that are pending will have to complete membership screening before they become full
	members that can talk.
]]
function Guild.Prototype.addGuildMemberAsync(
	self: Guild,
	userId: apiTypes.Snowflake,
	accessToken: string,

	nickname: string?,
	roles: { apiTypes.Snowflake }?,
	muted: boolean?,
	deafened: boolean?
): future.Future<member.Member?>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.addGuildMemberAsync(request, self.id, userId, {
				access_token = accessToken,
				nick = nickname,
				deaf = deafened,
				mute = muted,
				roles = roles,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		if response then
			return member.new(response)
		end

		return
	end)
end

--[[
	Removes a role from a guild member. Requires the MANAGE_ROLES permission.
]]
function Guild.Prototype.kickGuildMemberAsync(
	self: Guild,
	userId: apiTypes.Snowflake,
	reason: string?
): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.removeGuildMemberAsync(request, self.id, userId, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

--[[
	Create a guild ban, and optionally delete previous messages sent by the banned user.
]]
function Guild.Prototype.banGuildMemberAsync(
	self: Guild,
	userId: apiTypes.Snowflake,
	reason: string?,
	deleteMessageDays: number?,
	deleteMessageSeconds: number?
): future.Future<nil>
	return future.new(function()
		local request = self.state.rest:newRequest()

		if deleteMessageSeconds then
			assert(deleteMessageSeconds < 604800, "deleteMessageSeconds must be less than 604800")
			assert(deleteMessageSeconds > 0, "deleteMessageSeconds must be greater than 0")
		end

		if deleteMessageDays then
			assert(deleteMessageDays < 7, "deleteMessageDays must be less than 7")
			assert(deleteMessageDays > 0, "deleteMessageSeconds must be greater than 0")
		end

		local status, response = guildRest
			.createGuildBanAsync(request, self.id, userId, {
				delete_message_days = deleteMessageDays,
				delete_message_seconds = deleteMessageSeconds,
			}, reason)
			:await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

--[[
	Create a guild ban, and optionally delete previous messages sent by the banned user.
]]
function Guild.Prototype.bulkBanGuildMembersAsync(
	self: Guild,
	userIds: { apiTypes.Snowflake },
	reason: string?,
	deleteMessageSeconds: number?
): future.Future<{ failedUsers: { apiTypes.Snowflake }, bannedUsers: { apiTypes.Snowflake } }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		if deleteMessageSeconds then
			assert(deleteMessageSeconds < 604800, "deleteMessageSeconds must be less than 604800")
			assert(deleteMessageSeconds > 0, "deleteMessageSeconds must be greater than 0")
		end

		local status, response = guildRest
			.bulkGuildBanAsync(request, self.id, {
				user_ids = userIds,
				delete_message_seconds = deleteMessageSeconds,
			}, reason)
			:await()

		assert(status == "Fulfilled", tostring(response))

		local returnedValue = {}

		returnedValue.bannedUsers = response.banned_users
		returnedValue.failedUsers = response.failed_users

		return returnedValue
	end)
end

--[[
	Returns a list of ban objects for the users banned from this guild.
]]
function Guild.Prototype.getGuildBansAsync(
	self: Guild,
	limit: number?,
	before: apiTypes.Snowflake?,
	after: apiTypes.Snowflake?
): future.Future<{ ban.Ban }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.getGuildBansAsync(request, self.id, {
				limit = limit,
				before = before,
				after = after,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local bans = {}

		for _, banData in response do
			table.insert(bans, ban.new(banData))
		end

		return bans
	end)
end

--[[
	Returns a ban object for the given user or a 404 not found if the ban cannot be found.
]]
function Guild.Prototype.getGuildBanAsync(self: Guild, userId: apiTypes.Snowflake): future.Future<ban.Ban?>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.getGuildBanAsync(request, self.id, userId):await()

		assert(status == "Fulfilled", tostring(response))

		if response then
			return ban.new(response)
		end

		return
	end)
end

--[[
	Returns a list of role objects for the guild.
]]
function Guild.Prototype.getGuildRolesAsync(self: Guild): future.Future<{ role.Role }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.getGuildRolesAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local roles = {}

		for _, roleData in next, response do
			table.insert(roles, role.new(roleData))
		end

		return roles
	end)
end

--[[
	Returns a role object for the specified role.
]]
function Guild.Prototype.getGuildRoleAsync(self: Guild, roleId: apiTypes.Snowflake): future.Future<role.Role>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.getGuildRoleAsync(request, self.id, roleId):await()

		assert(status == "Fulfilled", tostring(response))

		return role.new(response)
	end)
end

--[[
	Create a new role for the guild. Requires the MANAGE_ROLES permission. Returns the new role object on success
]]
function Guild.Prototype.createGuildRoleAsync(
	self: Guild,
	roleJson: roleBuilder.JSON,
	reason: string?
): future.Future<role.Role>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.createGuildRoleAsync(request, self.id, roleJson, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return role.new(response)
	end)
end

--[[
	Modify a guild's MFA level. Requires guild ownership. Returns the updated level on success.
]]
function Guild.Prototype.setGuildMFALevelAsync(
	self: Guild,
	mfaLevel: guildTypes.MFALevel,
	reason: string?
): future.Future<guildTypes.MFALevel>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.modifyGuildMFALevelAsync(request, self.id, {
				level = guildTypes.MFALevel[mfaLevel],
			}, reason)
			:await()

		assert(status == "Fulfilled", tostring(response))

		return guildTypes.MFALevel[response]
	end)
end

--[[
	Returns an object with one pruned key indicating the number of members that would be removed in a prune operation.
	Requires the MANAGE_GUILD and KICK_MEMBERS permissions.

	By default, prune will not remove users with roles. You can optionally include specific roles in your prune by
	providing the include_roles parameter. Any inactive user that has a subset of the provided role(s) will be
	counted in the prune and users with additional roles will not.
]]
function Guild.Prototype.getGuildPruneCountAsync(
	self: Guild,
	days: number?,
	includedRoles: { apiTypes.Snowflake }?
): future.Future<number>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.getGuildPruneCountAsync(request, self.id, {
				days = days or 7,
				includeRoles = table.concat(includedRoles or {}, ","),
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return response.pruned
	end)
end

--[[
	Begin a prune operation. Requires the MANAGE_GUILD and KICK_MEMBERS permissions.
	Returns an object with one pruned key indicating the number of members that were removed in the prune operation.
	
	For large guilds it's recommended to set the compute_prune_count option to false, forcing pruned to null

	By default, prune will not remove users with roles. You can optionally include specific roles in your prune by
	providing the include_roles parameter. Any inactive user that has a subset of the provided role(s)
	will be included in the prune and users with additional roles will not.
]]
function Guild.Prototype.beginGuildPruneAsync(
	self: Guild,
	days: number?,
	returnPruneCount: boolean?,
	includedRoles: { apiTypes.Snowflake }?,
	reason: string?
): future.Future<number>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest
			.beginGuildPruneAsync(request, self.id, {
				days = days or 7,
				compute_prune_count = returnPruneCount or true,
				include_ruoles = includedRoles or {},
				reason = reason,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		if returnPruneCount then
			return response.pruned
		else
			return 0
		end
	end)
end

--[[
	Returns an array of voice region objects that can be used when setting a voice or stage channel's rtc_region.
]]
function Guild.Prototype.getGuildVoiceRegionsAsync(self: Guild): future.Future<{ voiceRegion.VoiceRegion }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.getGuildVoiceRegionsAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local voiceRegions = {}

		for _, voiceRegionData in response do
			table.insert(voiceRegions, voiceRegion.new(voiceRegionData))
		end

		return voiceRegions
	end)
end

--[[
	Returns a list of invite objects (with invite metadata) for the guild. Requires the MANAGE_GUILD permission.
]]
function Guild.Prototype.getGuildInvitesAsync(self: Guild): future.Future<{ invite.Invite }>
	return future.new(function()
		local request = self.state.rest:newRequest()

		local status, response = guildRest.getGuildInvitesAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local invites = {}

		for _, inviteData in response do
			table.insert(invites, invite.new(self.state, inviteData))
		end

		return invites
	end)
end

function Guild.Prototype.sync(self: Guild, guildData: apiTypes.GuildObject)
	local emojiArray = {}
	local rolesArray = {}
	local stickerArray = {}

	for _, emojiData in next, guildData.emojis or {} do
		table.insert(emojiArray, emoji.new(emojiData))
	end

	for _, roleData in next, guildData.roles or {} do
		table.insert(rolesArray, role.new(roleData))
	end

	for _, stickerData in next, guildData.stickers or {} do
		table.insert(stickerArray, sticker.new(stickerData))
	end

	if guildData.welcome_screen then
		self.welcomeScreen = welcomeScreen.new(guildData.welcome_screen)
	end

	self.stickers = stickerArray
	self.roles = rolesArray
	self.emojis = emojiArray

	self.verificationLevel = guildTypes.VerificationLevel[guildData.verification_level]
	self.defaultMessageNotifications = guildTypes.DefaultMessageNotification[guildData.default_message_notifications]
	self.explicitContentFilter = guildTypes.ExplicitContentFilterLevel[guildData.explicit_content_filter]
	self.premiumTier = guildTypes.PremiumTier[guildData.premium_tier]
	self.nsfwLevel = guildTypes.NSFWLevel[guildData.nsfw_level]
	self.mfaLevel = guildTypes.MFALevel[guildData.mfa_level]

	self.systemChannelFlags = guildData.system_channel_flags
		and systemChannelBitflag.new(guildData.system_channel_flags)

	self.icon = guildData.icon
	self.iconHash = guildData.icon_hash
	self.name = guildData.name
	self.splash = guildData.splash
	self.discoverySplash = guildData.discovery_splash
	self.owner = guildData.owner
	self.ownerId = guildData.owner_id
	self.permissions = guildData.permissions
	self.region = guildData.region
	self.afkChannelId = guildData.afk_channel_id
	self.afkTimeout = guildData.afk_timeout
	self.widgetEnabled = guildData.widget_enabled
	self.widgetChannelId = guildData.widget_channel_id
	self.features = guildData.features
	self.applicationId = guildData.application_id
	self.systemChannelId = guildData.system_channel_id
	self.rulesChannelId = guildData.rules_channel_id
	self.maxPresences = guildData.max_presences
	self.maxMembers = guildData.max_members
	self.vanityUrlCode = guildData.vanity_url_code
	self.description = guildData.description
	self.banner = guildData.banner
	self.premiumSubscriptionCount = guildData.premium_subscription_count
	self.preferredLocale = guildData.preferred_locale
	self.publicUpdatesChannelId = guildData.public_updates_channel_id
	self.maxVideoChannelUsers = guildData.max_video_channel_users
	self.maxStageVideoChannelUsers = guildData.max_stage_video_channel_users
	self.approximateMemberCount = guildData.approximate_member_count
	self.approximatePresenceCount = guildData.approximate_presence_count
	self.premiumProgressBarEnabled = guildData.premium_progress_bar_enabled
	self.safetyAlertsChannelId = guildData.safety_alerts_channel_id
end

function Guild.Interface.new(state: state.State, guildData: apiTypes.GuildObject): Guild
	local self = setmetatable(
		{
			state = state,

			id = guildData.id,
			isUnavailable = false,
		} :: Guild,
		{ __index = Guild.Prototype }
	)

	self:sync(guildData)

	return self
end

export type Guild = typeof(Guild.Prototype) & {
	state: state.State,

	id: apiTypes.Snowflake,
	isUnavailable: boolean,

	stickers: { sticker.Sticker },
	emojis: { emoji.Emoji },
	roles: { role.Role },
	welcomeScreen: welcomeScreen.WelcomeScreen?,

	icon: string?,
	iconHash: string?,
	name: string?,
	splash: string?,
	discoverySplash: string?,
	owner: boolean?,
	ownerId: apiTypes.Snowflake?,
	permissions: string?,
	region: string?,
	afkChannelId: apiTypes.Snowflake?,
	afkTimeout: number?,
	widgetEnabled: boolean?,
	widgetChannelId: apiTypes.Snowflake?,
	verificationLevel: guildTypes.VerificationLevel,
	defaultMessageNotifications: guildTypes.DefaultMessageNotification,
	explicitContentFilter: guildTypes.ExplicitContentFilterLevel,
	features: { apiTypes.GuildFeature }?,
	mfaLevel: guildTypes.MFALevel?,
	applicationId: apiTypes.Snowflake?,
	systemChannelId: apiTypes.Snowflake?,
	systemChannelFlags: systemChannelBitflag.SystemChannelBitflag?,
	rulesChannelId: apiTypes.Snowflake?,
	maxPresences: number?,
	maxMembers: number?,
	vanityUrlCode: string?,
	description: string?,
	banner: string?,
	premiumTier: guildTypes.PremiumTier,
	premiumSubscriptionCount: number?,
	preferredLocale: string?,
	publicUpdatesChannelId: apiTypes.Snowflake?,
	maxVideoChannelUsers: number?,
	maxStageVideoChannelUsers: number?,
	approximateMemberCount: number?,
	approximatePresenceCount: number?,
	nsfwLevel: guildTypes.NSFWLevel,
	premiumProgressBarEnabled: boolean?,
	safetyAlertsChannelId: apiTypes.Snowflake?,
}

return Guild.Interface
