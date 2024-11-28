--[[
	Implementation of the Discord Guild class in Luau

	https://discord.com/developers/docs/resources/guild#guild-object
]]

local async = require("../../lune_packages/async")
local apiTypes = require("../../lune_packages/api_types")
local state = require("../../lune_packages/state")
local builders = require("../../lune_packages/builders")
local rest = require("../../lune_packages/rest")

local emoji = require("../emoji")
local sticker = require("../sticker")
local role = require("./role")
local welcomeScreen = require("./welcomeScreen")
local preview = require("./preview")
local member = require("./member")
local ban = require("./ban")
local voiceRegion = require("./voiceRegion")
local invite = require("./invite")
local integration = require("./integration/integration")
local widget = require("./widget/widget")
local widgetSettings = require("./widget/widgetSettings")
local vanityUrl = require("./vanityUrl")
local onboarding = require("./onboarding/onboarding")

local guildAnnouncement = require("../channels/types/guildAnnouncement")
local guildCategory = require("../channels/types/guildCategory")
local guildDirectory = require("../channels/types/guildDirectory")
local guildStageVoice = require("../channels/types/guildStageVoice")
local guildText = require("../channels/types/guildText")
local guildVoice = require("../channels/types/guildVoice")

local announcementThread = require("../channels/threads/announcement")
local privateThread = require("../channels/threads/private")
local publicThread = require("../channels/threads/public")

local systemChannelBitflag = require("../bitflags/systemChannel")
local commandObject = require("../application/command/command")

local constructChannelFromData = require("../channels/construct")

local Guild = {}

Guild.Interface = {}
Guild.Prototype = {}

--[[
	Creates a guild Slash command for the application
]]
function Guild.Prototype.createSlashCommandAsync(
	self: Guild,
	slashCommand: builders.interactionJSON
): async.Async<commandObject.Command>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.commands
			.createGuildApplicationCommandAsync(request, self.state.applicationId, self.id, slashCommand)
			:await()

		assert(status == "Fulfilled", tostring(response))

		return commandObject.new(response)
	end)
end

--[[
	Delete an existing guild application command.
]]
function Guild.Prototype.deleteSlashCommandAsync(self: Guild, slashCommandId: apiTypes.Snowflake): async.Async<nil>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.commands
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
	slashCommand: builders.interactionJSON
): async.Async<commandObject.Command>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.commands
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
): async.Async<{ commandObject.Command }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.commands
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
	slashCommands: { builders.interactionJSON }
): async.Async<{ commandObject.Command }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local status, response = rest.commands
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
function Guild.Prototype.fetchGuildPreviewAsync(self: Guild): async.Async<preview.Preview>
	return async.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local status, response = rest.guild.getGuildPreviewAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		return preview.new(response)
	end)
end

--[[
	Modify a guild's settings. Requires the MANAGE_GUILD permission. Returns the updated guild object on success.
	Fires a Guild Update Gateway event.
]]
function Guild.Prototype.modifyGuildAsync(self: Guild, json: builders.guildJSON, reason: string?): async.Async<Guild>
	return async.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local status, response = rest.guild.modifyGuildAsync(request, self.id, json, reason):await()

		assert(status == "Fulfilled", tostring(response))

		self:sync(response)

		return self
	end)
end

--[[
	Delete a guild permanently. User must be owner. Returns 204 No Content on success.Fires a Guild Delete Gateway
	event.
]]
function Guild.Prototype.deleteGuildAsync(self: Guild): async.Async<nil>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.deleteGuildAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))
	end)
end

--[[
	Returns a list of guild channel objects. Does not include threads.

	Typed as unknown because the API returns a variety of channel types, and luau's type system is not currently
	capable of handling this.

	Please use explicit functions for specific channel types, for example: getTextChannelsAsync, getVoiceChannelsAsync, etc.
]]
function Guild.Prototype.getChannelsAsync(self: Guild): async.Async<{ type: apiTypes.ChannelType }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildChannelsAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local channels: { unknown } = {}

		for _, channelData in next, response do
			table.insert(channels, constructChannelFromData(self.state, channelData))
		end

		return channels
	end)
end

--[[
	Returns a list of guild text channel objects.
]]
function Guild.Prototype.getTextChannelsAsync(self: Guild): async.Async<{ guildText.GuildText }>
	return async.new(function()
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
function Guild.Prototype.getVoiceChannelsAsync(self: Guild): async.Async<{ guildVoice.GuildVoice }>
	return async.new(function()
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
function Guild.Prototype.getCategoryChannelsAsync(self: Guild): async.Async<{ guildText.GuildText }>
	return async.new(function()
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
function Guild.Prototype.getAnnouncementChannelsAsync(self: Guild): async.Async<{ guildAnnouncement.GuildAnnouncement }>
	return async.new(function()
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
function Guild.Prototype.getStageVoiceChannelsAsync(self: Guild): async.Async<{ guildStageVoice.GuildStageVoice }>
	return async.new(function()
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
function Guild.Prototype.getDirectoryChannelsAsync(self: Guild): async.Async<{ guildDirectory.GuildDirectory }>
	return async.new(function()
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
	json: builders.channelJSON,
	reason: string?
): async.Async<{ T }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.createGuildChannelAsync(request, self.id, json, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return constructChannelFromData(self.state, response)
	end)
end

--[[
	Returns all active threads in the guild, including public and private threads.
	Threads are ordered by their id, in descending order.

	Typed as unknown because the API returns a variety of channel types, and luau's type system is not currently
	capable of handling this.

	Please use explicit functions for specific channel types, for example: getMediaThreadsAsync, getAnnouncementThreadsAsync, etc.
]]
function Guild.Prototype.getThreadsAsync(self: Guild): async.Async<{ type: apiTypes.ChannelType }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.listActiveGuildThreadsAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local channels: { unknown } = {}

		for _, channelData in next, response.threads do
			table.insert(channels, constructChannelFromData(self.state, channelData))
		end

		return channels
	end)
end

--[[
	Returns a list of guild announcement thread objects.
]]
function Guild.Prototype.getAnnouncementThreadsAsync(self: Guild): async.Async<{ announcementThread.Announcement }>
	return async.new(function()
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
function Guild.Prototype.getPublicThreadsAsync(self: Guild): async.Async<{ publicThread.Public }>
	return async.new(function()
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
function Guild.Prototype.getPrivateThreadsAsync(self: Guild): async.Async<{ privateThread.Private }>
	return async.new(function()
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
function Guild.Prototype.getPrivateThreadsAsync(self: Guild): async.Async<{ privateThread.Private }>
	return async.new(function()
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
function Guild.Prototype.getGuildMemberAsync(self: Guild, userId: string): async.Async<member.Member>
	return async.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local status, response = rest.guild.getGuildMemberAsync(request, self.id, userId):await()

		assert(status == "Fulfilled", tostring(response))

		return member.new(self.state, self.id, response)
	end)
end

--[[
	Returns a list of guild member objects that are members of the guild.
]]
function Guild.Prototype.listGuildMembersAsync(
	self: Guild,
	lastSnowflake: string?,
	limit: number?
): async.Async<{ member.Member }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild
			.listGuildMembersAsync(request, self.id, {
				limit = limit,
				after = lastSnowflake,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local members = {}

		for _, memberData in response do
			table.insert(members, member.new(self.state, self.id, memberData))
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
): async.Async<{ member.Member }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild
			.searchGuildMembersAsync(request, self.id, {
				query = query,
				limit = limit,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		local members = {}

		for _, memberData in response do
			table.insert(members, member.new(self.state, self.id, memberData))
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
): async.Async<member.Member?>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild
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
			return member.new(self.state, self.id, response)
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
): async.Async<nil>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.removeGuildMemberAsync(request, self.id, userId, reason):await()

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
): async.Async<nil>
	return async.new(function()
		local request = self.state.rest:newRequest()

		if deleteMessageSeconds then
			assert(deleteMessageSeconds < 604800, "deleteMessageSeconds must be less than 604800")
			assert(deleteMessageSeconds > 0, "deleteMessageSeconds must be greater than 0")
		end

		if deleteMessageDays then
			assert(deleteMessageDays < 7, "deleteMessageDays must be less than 7")
			assert(deleteMessageDays > 0, "deleteMessageSeconds must be greater than 0")
		end

		local status, response = rest.guild
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
): async.Async<{ failedUsers: { apiTypes.Snowflake }, bannedUsers: { apiTypes.Snowflake } }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		if deleteMessageSeconds then
			assert(deleteMessageSeconds < 604800, "deleteMessageSeconds must be less than 604800")
			assert(deleteMessageSeconds > 0, "deleteMessageSeconds must be greater than 0")
		end

		local status, response = rest.guild
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
): async.Async<{ ban.Ban }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild
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
function Guild.Prototype.getGuildBanAsync(self: Guild, userId: apiTypes.Snowflake): async.Async<ban.Ban?>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildBanAsync(request, self.id, userId):await()

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
function Guild.Prototype.getGuildRolesAsync(self: Guild): async.Async<{ role.Role }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildRolesAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local roles = {}

		for _, roleData in next, response do
			table.insert(roles, role.new(self.state, self.id, roleData))
		end

		return roles
	end)
end

--[[
	Returns a role object for the specified role.
]]
function Guild.Prototype.getGuildRoleAsync(self: Guild, roleId: apiTypes.Snowflake): async.Async<role.Role>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildRoleAsync(request, self.id, roleId):await()

		assert(status == "Fulfilled", tostring(response))

		return role.new(self.state, self.id, response)
	end)
end

--[[
	Create a new role for the guild. Requires the MANAGE_ROLES permission. Returns the new role object on success
]]
function Guild.Prototype.createGuildRoleAsync(
	self: Guild,
	roleJson: builders.roleJSON,
	reason: string?
): async.Async<role.Role>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.createGuildRoleAsync(request, self.id, roleJson, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return role.new(self.state, self.id, response)
	end)
end

--[[
	Modify a guild's MFA level. Requires guild ownership. Returns the updated level on success.
]]
function Guild.Prototype.setGuildMFALevelAsync(
	self: Guild,
	mfaLevel: apiTypes.MFALevel,
	reason: string?
): async.Async<apiTypes.MFALevel>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild
			.modifyGuildMFALevelAsync(request, self.id, {
				level = apiTypes.guild.MFALevel[mfaLevel],
			}, reason)
			:await()

		assert(status == "Fulfilled", tostring(response))

		return apiTypes.guild.MFALevel[response]
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
): async.Async<number>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild
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
): async.Async<number>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild
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
function Guild.Prototype.getGuildVoiceRegionsAsync(self: Guild): async.Async<{ voiceRegion.VoiceRegion }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildVoiceRegionsAsync(request, self.id):await()

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
function Guild.Prototype.getGuildInvitesAsync(self: Guild): async.Async<{ invite.Invite }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildInvitesAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local invites = {}

		for _, inviteData in response do
			table.insert(invites, invite.new(self.state, inviteData))
		end

		return invites
	end)
end

--[[
	Returns a list of integration objects for the guild. Requires the MANAGE_GUILD permission.
]]
function Guild.Prototype.getGuildIntegrationsAsync(self: Guild): async.Async<{ integration.Integration }>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildIntegrationsAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		local integrations = {}

		for _, integrationData in response do
			table.insert(integrations, integration.new(integrationData))
		end

		return integrations
	end)
end

--[[
	Delete the attached integration object for the guild. Deletes any associated webhooks and kicks the associated
	bot if there is one.
	
	Requires the MANAGE_GUILD permission.
]]
function Guild.Prototype.deleteGuildIntegrationAsync(self: Guild, integrationId: string): async.Async<nil>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.deleteGuildIntegrationAsync(request, self.id, integrationId):await()

		assert(status == "Fulfilled", tostring(response))

		return
	end)
end

--[[
	Returns a guild widget settings object. Requires the MANAGE_GUILD permission.
]]
function Guild.Prototype.getGuildWidgetSettingsAsync(self: Guild): async.Async<widgetSettings.WidgetSettings>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildWidgetSettingsAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		return widgetSettings.new(response)
	end)
end

--[[
	Modify a guild widget settings object for the guild. All attributes may be passed in with JSON and modified.
	Requires the MANAGE_GUILD permission. Returns the updated guild widget settings object. 
]]
function Guild.Prototype.modifyGuildWidgetAsync(
	self: Guild,
	json: builders.widgetSettingsJSON,
	reason: string?
): async.Async<widgetSettings.WidgetSettings>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.modifyGuildWidgetAsync(request, self.id, json, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return widgetSettings.new(response)
	end)
end

--[[
	Returns the widget for the guild. Fires an Invite Create Gateway event when an invite channel is defined
	and a new Invite is generated.
]]
function Guild.Prototype.getGuildWidgetAsync(self: Guild): async.Async<widget.Widget>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildWidgetAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		return widget.new(self.state, response)
	end)
end

--[[
	Returns a partial invite object for guilds with that feature enabled. Requires the MANAGE_GUILD permission.
	code will be null if a vanity url for the guild is not set.
]]
function Guild.Prototype.getGuildVanityUrlAsync(self: Guild): async.Async<vanityUrl.VanityUrl>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildVanityURLAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		return vanityUrl.new(response)
	end)
end

--[[
	Returns a PNG image widget for the guild. Requires no permissions or authentication.
]]
function Guild.Prototype.getGuildWidgetImageAsync(
	self: Guild,
	style: "shield" | "banner1" | "banner2" | "banner3" | "banner4"
): async.Async<string>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild
			.getGuildWidgetImageAsync(request, self.id, {
				style = style,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))

		return response
	end)
end

--[[
	Returns the Welcome Screen object for the guild. If the welcome screen is not enabled.
	
	the MANAGE_GUILD permission is required.
]]
function Guild.Prototype.getGuildWelcomeScreenAsync(self: Guild): async.Async<welcomeScreen.WelcomeScreen>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildWelcomeScreenAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		return welcomeScreen.new(response)
	end)
end

--[[
	Modify the guild's Welcome Screen. Requires the MANAGE_GUILD permission.
]]
function Guild.Prototype.modifyGuildWelcomeScreenAsync(
	self: Guild,
	json: builders.welcomeScreenJSON,
	reason: string?
): async.Async<welcomeScreen.WelcomeScreen>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.modifyGuildWelcomeScreenAsync(request, self.id, json, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return welcomeScreen.new(response)
	end)
end

--[[
	Returns the Onboarding object for the guild.
]]
function Guild.Prototype.getGuildOnboardingAsync(self: Guild): async.Async<onboarding.Onboarding>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.getGuildOnboardingAsync(request, self.id):await()

		assert(status == "Fulfilled", tostring(response))

		return onboarding.new(response)
	end)
end

--[[
	Modifies the onboarding configuration of the guild. Returns a 200 with the Onboarding object for the guild.
	Requires the MANAGE_GUILD and MANAGE_ROLES permissions.
]]
function Guild.Prototype.modifyGuildOnboardingAsync(
	self: Guild,
	json: builders.onboardingJSON,
	reason: string?
): async.Async<onboarding.Onboarding>
	return async.new(function()
		local request = self.state.rest:newRequest()

		local status, response = rest.guild.modifyGuildOnboardingAsync(request, self.id, json, reason):await()

		assert(status == "Fulfilled", tostring(response))

		return onboarding.new(response)
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
		table.insert(rolesArray, role.new(self.state, self.id, roleData))
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

	self.verificationLevel = apiTypes.guild.VerificationLevel[guildData.verification_level]
	self.defaultMessageNotifications =
		apiTypes.guild.DefaultMessageNotification[guildData.default_message_notifications]
	self.explicitContentFilter = apiTypes.guild.ExplicitContentFilterLevel[guildData.explicit_content_filter]
	self.premiumTier = apiTypes.guild.PremiumTier[guildData.premium_tier]
	self.nsfwLevel = apiTypes.guild.NSFWLevel[guildData.nsfw_level]
	self.mfaLevel = apiTypes.guild.MFALevel[guildData.mfa_level]

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
	verificationLevel: apiTypes.VerificationLevel,
	defaultMessageNotifications: apiTypes.DefaultMessageNotification,
	explicitContentFilter: apiTypes.ExplicitContentFilterLevel,
	features: { apiTypes.GuildFeature }?,
	mfaLevel: apiTypes.MFALevel?,
	applicationId: apiTypes.Snowflake?,
	systemChannelId: apiTypes.Snowflake?,
	systemChannelFlags: systemChannelBitflag.SystemChannelBitflag?,
	rulesChannelId: apiTypes.Snowflake?,
	maxPresences: number?,
	maxMembers: number?,
	vanityUrlCode: string?,
	description: string?,
	banner: string?,
	premiumTier: apiTypes.PremiumTier,
	premiumSubscriptionCount: number?,
	preferredLocale: string?,
	publicUpdatesChannelId: apiTypes.Snowflake?,
	maxVideoChannelUsers: number?,
	maxStageVideoChannelUsers: number?,
	approximateMemberCount: number?,
	approximatePresenceCount: number?,
	nsfwLevel: apiTypes.NSFWLevel,
	premiumProgressBarEnabled: boolean?,
	safetyAlertsChannelId: apiTypes.Snowflake?,
}

return Guild.Interface
