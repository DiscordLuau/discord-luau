--[[
	Implementation of the Discord Guild class in Luau

	https://discord.com/developers/docs/resources/guild#guild-object
]]

local future = require("../../luau_packages/future")
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
function Guild.Prototype.createSlashCommandAsync(self: Guild, slashCommand: builders.interactionJSON)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.commands
			.createGuildApplicationCommandAsync(request, self.state.applicationId, self.id, slashCommand)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return commandObject.new(response:unwrapOk())
	end) :: future.FutureLike<string, commandObject.Command>
end

--[[
	Delete an existing guild application command.
]]
function Guild.Prototype.deleteSlashCommandAsync(self: Guild, slashCommandId: apiTypes.Snowflake)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.commands
			.deleteGuildApplicationCommandAsync(request, self.state.applicationId, self.id, slashCommandId)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Edit an existing guild application command.
]]
function Guild.Prototype.editSlashCommandAsync(
	self: Guild,
	slashCommandId: apiTypes.Snowflake,
	slashCommand: builders.interactionJSON
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.commands
			.editGuildApplicationCommandAsync(request, self.state.applicationId, self.id, slashCommandId, slashCommand)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return commandObject.new(response:unwrapOk())
	end) :: future.FutureLike<string, commandObject.Command>
end

--[[
	Get a list of guild application commands.
]]
function Guild.Prototype.getSlashCommandsAsync(self: Guild, withLocalizations: boolean?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.commands
			.getGuildApplicationCommandsAsync(request, self.state.applicationId, self.id, {
				withLocalizations = withLocalizations,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local commands = {}

		for _, commandData in response:unwrapOk() do
			table.insert(commands, commandObject.new(commandData))
		end

		return commands
	end) :: future.FutureLike<string, { commandObject.Command }>
end

--[[
	Overwrite all guild application commands. This will skip over commands that are the same as the current commands,
	and will not remove any existing commands.
]]
function Guild.Prototype.overwriteSlashCommandsAsync(self: Guild, slashCommands: { builders.interactionJSON })
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local response = rest.commands
			.bulkOverwriteGuildApplicationCommandsAsync(request, self.state.applicationId, self.id, slashCommands :: any)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local commands = {}

		for _, commandData in response:unwrapOk() do
			table.insert(commands, commandObject.new(commandData))
		end

		return commands
	end) :: future.FutureLike<string, { commandObject.Command }>
end

--[[
	Returns the guild preview object for the given id. If the user is not in the guild, then the guild must be
	discoverable.
]]
function Guild.Prototype.fetchGuildPreviewAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local response = rest.guild.getGuildPreviewAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return preview.new(response:unwrapOk())
	end) :: future.FutureLike<string, preview.Preview>
end

--[[
	Modify a guild's settings. Requires the MANAGE_GUILD permission. Returns the updated guild object on success.
	Fires a Guild Update Gateway event.
]]
function Guild.Prototype.modifyGuildAsync(self: Guild, json: builders.guildJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local response = rest.guild.modifyGuildAsync(request, self.id, json, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		self:sync(response:unwrapOk())

		return self
	end) :: future.FutureLike<string, Guild>
end

--[[
	Delete a guild permanently. User must be owner. Returns 204 No Content on success.Fires a Guild Delete Gateway
	event.
]]
function Guild.Prototype.deleteGuildAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.deleteGuildAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Returns a list of guild channel objects. Does not include threads.

	Typed as unknown because the API returns a variety of channel types, and luau's type system is not currently
	capable of handling this.

	Please use explicit functions for specific channel types, for example: getTextChannelsAsync, getVoiceChannelsAsync, etc.
]]
function Guild.Prototype.getChannelsAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildChannelsAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local channels: { unknown } = {}

		for _, channelData in next, response:unwrapOk() do
			table.insert(channels, constructChannelFromData(self.state, channelData))
		end

		return channels :: any
	end) :: future.FutureLike<string, { apiTypes.AbstractChannel }>
end

--[[
	Returns a list of guild text channel objects.
]]
function Guild.Prototype.getTextChannelsAsync(self: Guild)
	return future.Future.new(function()
		local channels = self:getChannelsAsync():await()

		if channels:isOk() then
			local resolvedChannels: { guildText.GuildText } = {}

			for _, channel in next, channels:unwrapOk() do
				if channel.type ~= "GuildText" then
					continue
				end

				table.insert(resolvedChannels, channel :: any)
			end

			return resolvedChannels
		else
			error(channels:unwrapErr())
		end
	end) :: future.FutureLike<string, { guildText.GuildText }>
end

--[[
	Returns a list of guild voice channel objects.
]]
function Guild.Prototype.getVoiceChannelsAsync(self: Guild)
	return future.Future.new(function()
		local channels = self:getChannelsAsync():await()

		if channels:isOk() then
			local resolvedChannels: { guildText.GuildText } = {}

			for _, channel in next, channels:unwrapOk() do
				if channel.type ~= "GuildVoice" then
					continue
				end

				table.insert(resolvedChannels, channel :: any)
			end

			return resolvedChannels :: any
		else
			error(channels:unwrapErr())
		end
	end) :: future.FutureLike<string, { guildVoice.GuildVoice }>
end

--[[
	Returns a list of guild category channel objects.
]]
function Guild.Prototype.getCategoryChannelsAsync(self: Guild)
	return future.Future.new(function()
		local channels = self:getChannelsAsync():await()

		if channels:isOk() then
			local resolvedChannels: { guildText.GuildText } = {}

			for _, channel in next, channels:unwrapOk() do
				if channel.type ~= "GuildCategory" then
					continue
				end

				table.insert(resolvedChannels, channel :: any)
			end

			return resolvedChannels :: any
		else
			error(channels:unwrapErr())
		end
	end) :: future.FutureLike<string, { guildCategory.GuildCategory }>
end

--[[
	Returns a list of guild announcement channel objects.
]]
function Guild.Prototype.getAnnouncementChannelsAsync(self: Guild)
	return future.Future.new(function()
		local channels = self:getChannelsAsync():await()

		if channels:isOk() then
			local resolvedChannels: { guildText.GuildText } = {}

			for _, channel in next, channels:unwrapOk() do
				if channel.type ~= "GuildAnnouncement" then
					continue
				end

				table.insert(resolvedChannels, channel :: any)
			end

			return resolvedChannels
		else
			error(channels:unwrapErr())
		end
	end) :: future.FutureLike<string, { guildAnnouncement.GuildAnnouncement }>
end

--[[
	Returns a list of guild stage voice channel objects.
]]
function Guild.Prototype.getStageVoiceChannelsAsync(self: Guild)
	return future.Future.new(function()
		local channels = self:getChannelsAsync():await()

		if channels:isOk() then
			local resolvedChannels: { guildText.GuildText } = {}

			for _, channel in next, channels:unwrapOk() do
				if channel.type ~= "GuildStageVoice" then
					continue
				end

				table.insert(resolvedChannels, channel :: any)
			end

			return resolvedChannels :: any
		else
			error(channels:unwrapErr())
		end
	end) :: future.FutureLike<string, { guildStageVoice.GuildStageVoice }>
end

--[[
	Returns a list of guild directory channel objects.
]]
function Guild.Prototype.getDirectoryChannelsAsync(self: Guild)
	return future.Future.new(function()
		local channels = self:getChannelsAsync():await()

		if channels:isOk() then
			local resolvedChannels: { guildText.GuildText } = {}

			for _, channel in next, channels:unwrapOk() do
				if channel.type ~= "GuildDirectory" then
					continue
				end

				table.insert(resolvedChannels, channel :: any)
			end

			return resolvedChannels :: any
		else
			error(channels:unwrapErr())
		end
	end) :: future.FutureLike<string, { guildDirectory.GuildDirectory }>
end

--[[
	Create a new channel object for the guild. Requires the MANAGE_CHANNELS permission. If setting permission
	overwrites, only permissions your bot has in the guild can be allowed/denied.
	
	Setting MANAGE_ROLES permission in channels is only possible for guild administrators.
	
	Returns the new channel object on success.
	
	Fires a Channel Create Gateway event.
]]
function Guild.Prototype.createChannelAsync<T>(self: Guild, json: builders.channelJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.createGuildChannelAsync(request, self.id, json, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return constructChannelFromData(self.state, response:unwrapOk()) :: any
	end) :: future.FutureLike<string, { apiTypes.AbstractChannel }>
end

--[[
	Returns all active threads in the guild, including public and private threads.
	Threads are ordered by their id, in descending order.

	Typed as unknown because the API returns a variety of channel types, and luau's type system is not currently
	capable of handling this.

	Please use explicit functions for specific channel types, for example: getMediaThreadsAsync, getAnnouncementThreadsAsync, etc.
]]
function Guild.Prototype.getThreadsAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.listActiveGuildThreadsAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local channels: { unknown } = {}

		for _, channelData in next, response:unwrapOk().threads do
			table.insert(channels, constructChannelFromData(self.state, channelData))
		end

		return channels :: any
	end) :: future.FutureLike<string, { publicThread.Public | privateThread.Private }>
end

--[[
	Returns a list of guild announcement thread objects.
]]
function Guild.Prototype.getAnnouncementThreadsAsync(self: Guild)
	return future.Future.new(function()
		local channels = self:getChannelsAsync():await()

		if channels:isOk() then
			local resolvedChannels: { guildText.GuildText } = {}

			for _, channel in next, channels:unwrapOk() do
				if channel.type ~= "AnnouncementThread" then
					continue
				end

				table.insert(resolvedChannels, channel :: any)
			end

			return resolvedChannels :: any
		else
			error(channels:unwrapErr())
		end
	end) :: future.FutureLike<string, { announcementThread.Announcement }>
end

--[[
	Returns a list of public guild thread objects.
]]
function Guild.Prototype.getPublicThreadsAsync(self: Guild)
	return future.Future.new(function()
		local channels = self:getChannelsAsync():await()

		if channels:isOk() then
			local resolvedChannels: { guildText.GuildText } = {}

			for _, channel in next, channels:unwrapOk() do
				if channel.type ~= "PublicThread" then
					continue
				end

				table.insert(resolvedChannels, channel :: any)
			end

			return resolvedChannels :: any
		else
			error(channels:unwrapErr())
		end
	end) :: future.FutureLike<string, { publicThread.Public }>
end

--[[
	Returns a list of private guild thread objects.
]]
function Guild.Prototype.getPrivateThreadsAsync(self: Guild)
	return future.Future.new(function()
		local channels = self:getChannelsAsync():await()

		if channels:isOk() then
			local resolvedChannels: { guildText.GuildText } = {}

			for _, channel in next, channels:unwrapOk() do
				if channel.type ~= "PrivateThread" then
					continue
				end

				table.insert(resolvedChannels, channel :: any)
			end

			return resolvedChannels :: any
		else
			error(channels:unwrapErr())
		end
	end) :: future.FutureLike<string, { privateThread.Private }>
end

--[[
	Returns a guild member object for the specified user.
]]
function Guild.Prototype.getGuildMemberAsync(self: Guild, userId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		-- fixme: casted this as any, the command object itself has extra fields as required by the other APIs
		local response = rest.guild.getGuildMemberAsync(request, self.id, userId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return member.new(self.state, self.id, response:unwrapOk())
	end) :: future.FutureLike<string, member.Member>
end

--[[
	Returns a list of guild member objects that are members of the guild.
]]
function Guild.Prototype.listGuildMembersAsync(self: Guild, lastSnowflake: string?, limit: number?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.listGuildMembersAsync(request, self.id, {
				limit = limit,
				after = lastSnowflake,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local members = {}

		for _, memberData in response:unwrapOk() do
			table.insert(members, member.new(self.state, self.id, memberData))
		end

		return members
	end) :: future.FutureLike<string, { member.Member }>
end

--[[
	Returns a list of guild member objects whose username or nickname starts with a provided string.
]]
function Guild.Prototype.searchGuildMembersAsync(self: Guild, query: string, limit: number?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.searchGuildMembersAsync(request, self.id, {
				query = query,
				limit = limit,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local members = {}

		for _, memberData in response:unwrapOk() do
			table.insert(members, member.new(self.state, self.id, memberData))
		end

		return members
	end) :: future.FutureLike<string, { member.Member }>
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
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.addGuildMemberAsync(request, self.id, userId, {
				access_token = accessToken,
				nick = nickname,
				deaf = deafened,
				mute = muted,
				roles = roles,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local data = response:unwrapOk()

		if data then
			return member.new(self.state, self.id, data) :: any
		else
			return nil :: any
		end
	end) :: future.FutureLike<string, member.Member?>
end

--[[
	Removes a role from a guild member. Requires the MANAGE_ROLES permission.
]]
function Guild.Prototype.kickGuildMemberAsync(self: Guild, userId: apiTypes.Snowflake, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.removeGuildMemberAsync(request, self.id, userId, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
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
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		if deleteMessageSeconds then
			assert(deleteMessageSeconds < 604800, "deleteMessageSeconds must be less than 604800")
			assert(deleteMessageSeconds > 0, "deleteMessageSeconds must be greater than 0")
		end

		if deleteMessageDays then
			assert(deleteMessageDays < 7, "deleteMessageDays must be less than 7")
			assert(deleteMessageDays > 0, "deleteMessageSeconds must be greater than 0")
		end

		local response = rest.guild
			.createGuildBanAsync(request, self.id, userId, {
				delete_message_days = deleteMessageDays,
				delete_message_seconds = deleteMessageSeconds,
			}, reason)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Create a guild ban, and optionally delete previous messages sent by the banned user.
]]
function Guild.Prototype.bulkBanGuildMembersAsync(
	self: Guild,
	userIds: { apiTypes.Snowflake },
	reason: string?,
	deleteMessageSeconds: number?
): future.Future<
	string,
	{ failedUsers: { apiTypes.Snowflake }, bannedUsers: { apiTypes.Snowflake } }
>
	return future.Future.new(
			function()
				local request = self.state.rest:newRequest()

				if deleteMessageSeconds then
					assert(deleteMessageSeconds < 604800, "deleteMessageSeconds must be less than 604800")
					assert(deleteMessageSeconds > 0, "deleteMessageSeconds must be greater than 0")
				end

				local response = rest.guild
					.bulkGuildBanAsync(request, self.id, {
						user_ids = userIds,
						delete_message_seconds = deleteMessageSeconds,
					}, reason)
					:await()

				assert(response:isOk(), tostring(response:unwrapErr()))

				local data = response:unwrapOk()
				local returnedValue = {}

				returnedValue.bannedUsers = data.banned_users
				returnedValue.failedUsers = data.failed_users

				return returnedValue
			end
		) :: future.FutureLike<string, { bannedUsers: { apiTypes.Snowflake }, failedUsers: { apiTypes.Snowflake } }>
end

--[[
	Returns a list of ban objects for the users banned from this guild.
]]
function Guild.Prototype.getGuildBansAsync(
	self: Guild,
	limit: number?,
	before: apiTypes.Snowflake?,
	after: apiTypes.Snowflake?
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.getGuildBansAsync(request, self.id, {
				limit = limit,
				before = before,
				after = after,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local bans = {}

		for _, banData in response:unwrapOk() do
			table.insert(bans, ban.new(banData))
		end

		return bans
	end) :: future.FutureLike<string, { ban.Ban }>
end

--[[
	Returns a ban object for the given user or a 404 not found if the ban cannot be found.
]]
function Guild.Prototype.getGuildBanAsync(self: Guild, userId: apiTypes.Snowflake)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildBanAsync(request, self.id, userId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local data = response:unwrapOk()

		if data then
			return ban.new(data) :: any
		else
			return nil :: any
		end
	end) :: future.FutureLike<string, ban.Ban?>
end

--[[
	Returns a list of role objects for the guild.
]]
function Guild.Prototype.getGuildRolesAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildRolesAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local roles = {}

		for _, roleData in next, response:unwrapOk() do
			table.insert(roles, role.new(self.state, self.id, roleData))
		end

		return roles
	end) :: future.FutureLike<string, { role.Role }>
end

--[[
	Returns a role object for the specified role.
]]
function Guild.Prototype.getGuildRoleAsync(self: Guild, roleId: apiTypes.Snowflake)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildRoleAsync(request, self.id, roleId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return role.new(self.state, self.id, response:unwrapOk())
	end) :: future.FutureLike<string, role.Role>
end

--[[
	Create a new role for the guild. Requires the MANAGE_ROLES permission. Returns the new role object on success
]]
function Guild.Prototype.createGuildRoleAsync(self: Guild, roleJson: builders.roleJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.createGuildRoleAsync(request, self.id, roleJson, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return role.new(self.state, self.id, response:unwrapOk())
	end) :: future.FutureLike<string, role.Role>
end

--[[
	Modify a guild's MFA level. Requires guild ownership. Returns the updated level on success.
]]
function Guild.Prototype.setGuildMFALevelAsync(self: Guild, mfaLevel: apiTypes.MFALevel, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.modifyGuildMFALevelAsync(request, self.id, {
				level = apiTypes.guild.MFALevel[mfaLevel],
			}, reason)
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return apiTypes.guild.MFALevel[response:unwrapOk()]
	end) :: future.FutureLike<string, apiTypes.MFALevel>
end

--[[
	Returns an object with one pruned key indicating the number of members that would be removed in a prune operation.
	Requires the MANAGE_GUILD and KICK_MEMBERS permissions.

	By default, prune will not remove users with roles. You can optionally include specific roles in your prune by
	providing the include_roles parameter. Any inactive user that has a subset of the provided role(s) will be
	counted in the prune and users with additional roles will not.
]]
function Guild.Prototype.getGuildPruneCountAsync(self: Guild, days: number?, includedRoles: { apiTypes.Snowflake }?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.getGuildPruneCountAsync(request, self.id, {
				days = days or 7,
				includeRoles = table.concat(includedRoles or {}, ","),
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk().pruned
	end) :: future.FutureLike<string, number>
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
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.beginGuildPruneAsync(request, self.id, {
				days = days or 7,
				compute_prune_count = returnPruneCount or true,
				include_ruoles = includedRoles or {},
				reason = reason,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		if returnPruneCount then
			return response:unwrapOk().pruned
		else
			return 0
		end
	end) :: future.FutureLike<string, number>
end

--[[
	Returns an array of voice region objects that can be used when setting a voice or stage channel's rtc_region.
]]
function Guild.Prototype.getGuildVoiceRegionsAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildVoiceRegionsAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local voiceRegions = {}

		for _, voiceRegionData in response:unwrapOk() do
			table.insert(voiceRegions, voiceRegion.new(voiceRegionData))
		end

		return voiceRegions
	end) :: future.FutureLike<string, { voiceRegion.VoiceRegion }>
end

--[[
	Returns a list of invite objects (with invite metadata) for the guild. Requires the MANAGE_GUILD permission.
]]
function Guild.Prototype.getGuildInvitesAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildInvitesAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local invites = {}

		for _, inviteData in response:unwrapOk() do
			table.insert(invites, invite.new(self.state, inviteData))
		end

		return invites
	end) :: future.FutureLike<string, { invite.Invite }>
end

--[[
	Returns a list of integration objects for the guild. Requires the MANAGE_GUILD permission.
]]
function Guild.Prototype.getGuildIntegrationsAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildIntegrationsAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		local integrations = {}

		for _, integrationData in response:unwrapOk() do
			table.insert(integrations, integration.new(integrationData))
		end

		return integrations
	end) :: future.FutureLike<string, { integration.Integration }>
end

--[[
	Delete the attached integration object for the guild. Deletes any associated webhooks and kicks the associated
	bot if there is one.
	
	Requires the MANAGE_GUILD permission.
]]
function Guild.Prototype.deleteGuildIntegrationAsync(self: Guild, integrationId: string)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.deleteGuildIntegrationAsync(request, self.id, integrationId):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[[
	Returns a guild widget settings object. Requires the MANAGE_GUILD permission.
]]
function Guild.Prototype.getGuildWidgetSettingsAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildWidgetSettingsAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return widgetSettings.new(response:unwrapOk())
	end) :: future.FutureLike<string, widgetSettings.WidgetSettings>
end

--[[
	Modify a guild widget settings object for the guild. All attributes may be passed in with JSON and modified.
	Requires the MANAGE_GUILD permission. Returns the updated guild widget settings object. 
]]
function Guild.Prototype.modifyGuildWidgetAsync(self: Guild, json: builders.widgetSettingsJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.modifyGuildWidgetAsync(request, self.id, json, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return widgetSettings.new(response:unwrapOk())
	end) :: future.FutureLike<string, widgetSettings.WidgetSettings>
end

--[[
	Returns the widget for the guild. Fires an Invite Create Gateway event when an invite channel is defined
	and a new Invite is generated.
]]
function Guild.Prototype.getGuildWidgetAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildWidgetAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return widget.new(self.state, response:unwrapOk())
	end) :: future.FutureLike<string, widget.Widget>
end

--[[
	Returns a partial invite object for guilds with that feature enabled. Requires the MANAGE_GUILD permission.
	code will be null if a vanity url for the guild is not set.
]]
function Guild.Prototype.getGuildVanityUrlAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildVanityURLAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return vanityUrl.new(response:unwrapOk())
	end) :: future.FutureLike<string, vanityUrl.VanityUrl>
end

--[[
	Returns a PNG image widget for the guild. Requires no permissions or authentication.
]]
function Guild.Prototype.getGuildWidgetImageAsync(
	self: Guild,
	style: "shield" | "banner1" | "banner2" | "banner3" | "banner4"
)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild
			.getGuildWidgetImageAsync(request, self.id, {
				style = style,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return response:unwrapOk()
	end) :: future.FutureLike<string, string>
end

--[[
	Returns the Welcome Screen object for the guild. If the welcome screen is not enabled.
	
	the MANAGE_GUILD permission is required.
]]
function Guild.Prototype.getGuildWelcomeScreenAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildWelcomeScreenAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return welcomeScreen.new(response:unwrapOk())
	end) :: future.FutureLike<string, welcomeScreen.WelcomeScreen>
end

--[[
	Modify the guild's Welcome Screen. Requires the MANAGE_GUILD permission.
]]
function Guild.Prototype.modifyGuildWelcomeScreenAsync(self: Guild, json: builders.welcomeScreenJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.modifyGuildWelcomeScreenAsync(request, self.id, json, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return welcomeScreen.new(response:unwrapOk())
	end) :: future.FutureLike<string, welcomeScreen.WelcomeScreen>
end

--[[
	Returns the Onboarding object for the guild.
]]
function Guild.Prototype.getGuildOnboardingAsync(self: Guild)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.getGuildOnboardingAsync(request, self.id):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return onboarding.new(response:unwrapOk())
	end) :: future.FutureLike<string, onboarding.Onboarding>
end

--[[
	Modifies the onboarding configuration of the guild. Returns a 200 with the Onboarding object for the guild.
	Requires the MANAGE_GUILD and MANAGE_ROLES permissions.
]]
function Guild.Prototype.modifyGuildOnboardingAsync(self: Guild, json: builders.onboardingJSON, reason: string?)
	return future.Future.new(function()
		local request = self.state.rest:newRequest()

		local response = rest.guild.modifyGuildOnboardingAsync(request, self.id, json, reason):await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return onboarding.new(response:unwrapOk())
	end) :: future.FutureLike<string, onboarding.Onboarding>
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
