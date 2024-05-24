local Datetime = require("../../Std/Datetime")

local Construct = require("../../Utils/Construct")

local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local CacheType = require("../../Enums/CacheType")

local Future = require("../../Vendor/Future")

local DiscordUser = require("DiscordUser")

--[=[
	@class Objects.DiscordGuildMember

	The `DiscordGuildMember` class represents a member of a Discord guild (server) and provides methods to interact with and manage the guild member.
]=]
local DiscordGuildMember = {}

DiscordGuildMember.Prototype = {}
DiscordGuildMember.Interface = {}

--[=[
	@prop type string
	@within Objects.DiscordGuildMember
	@readonly

	The type of the DiscordGuildMember. Default is "DiscordGuildMember".
]=]
DiscordGuildMember.Prototype.type = "DiscordGuildMember"

--[=[
	Kicks the guild member asynchronously.

	@method kickAsync
	@param deleteMessagesSeconds number? -- The number of seconds of messages to delete.
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.kickAsync(self: DiscordGuildMember, deleteMessagesSeconds: number?)
	return self.discordClient.discordGateway:putAsync(string.format(DiscordEndpoints.BotBanGuildMember, self.guildId, self.user.id), {
		delete_message_seconds = deleteMessagesSeconds or 0
	}):await()
end

--[=[
	Bans the guild member asynchronously.

	@method banAsync
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.banAsync(self: DiscordGuildMember)
	return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotRemoveGuildMember, self.guildId, self.user.id)):await()
end

--[=[
	Unbans the guild member asynchronously.

	@method unbanAsync
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.unbanAsync(self: DiscordGuildMember)
	return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotRemoveGuildMemberBan, self.guildId, self.user.id)):await()
end

--[=[
	Adds a role to the guild member asynchronously.

	@method addRoleAsync
	@param roleId string -- The ID of the role to add.
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.addRoleAsync(self: DiscordGuildMember, roleId: string)
	return self.discordClient.discordGateway:putAsync(string.format(DiscordEndpoints.BotAddGuildMemberRole, self.guildId, self.user.id, roleId)):await()
end

--[=[
	Removes a role from the guild member asynchronously.

	@method removeRoleAsync
	@param roleId string -- The ID of the role to remove.
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.removeRoleAsync(self: DiscordGuildMember, roleId: string)
	return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotRemoveGuildMemberRole, self.guildId, self.user.id, roleId)):await()
end

--[=[
	Times out the guild member asynchronously.

	@method timeoutAsync
	@param seconds number -- The duration of the timeout in seconds.
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.timeoutAsync(self: DiscordGuildMember, seconds: number)
	return self:modifyAsync({
		timeoutUntil = seconds,
	})
end

--[=[
	Mutes the guild member asynchronously.

	@method muteAsync
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.muteAsync(self: DiscordGuildMember)
	return self:modifyAsync({
		mute = true,
	})
end

--[=[
	Unmutes the guild member asynchronously.

	@method unmuteAsync
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.unmuteAsync(self: DiscordGuildMember)
	return self:modifyAsync({
		mute = false,
	})
end

--[=[
	Deafens the guild member asynchronously.

	@method deafenAsync
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.deafenAsync(self: DiscordGuildMember)
	return self:modifyAsync({
		deaf = true,
	})
end

--[=[
	Undeafens the guild member asynchronously.

	@method undeafenAsync
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.undeafenAsync(self: DiscordGuildMember)
	return self:modifyAsync({
		deaf = false,
	})
end

--[=[
	Sets the nickname of the guild member asynchronously.

	@method setNicknameAsync
	@param nickname string -- The new nickname.
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.setNicknameAsync(self: DiscordGuildMember, nickname: string)
	return self:modifyAsync({
		nickname = nickname,
	})
end

--[=[
	Modifies the guild member asynchronously.

	@method modifyAsync
	@param modificationsTable table -- A table containing the modifications.
	@return Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.modifyAsync(self: DiscordGuildMember, modificationsTable: {
	nickname: string?,
	roles: { string }?,
	mute: boolean?,
	deaf: boolean?,
	channelId: string?,
	timeoutUntil: number?,
	flags: number?
})
	local communication_disabled_until

	if modificationsTable.timeoutUntil then
		communication_disabled_until = Datetime.fromUnixTimestamp(
			os.time() + modificationsTable.timeoutUntil
		):toIsoDate()
	end

	return self.discordClient.discordGateway:patchAsync(string.format(DiscordEndpoints.BotModifyGuildMember, self.guildId, self.user.id), {
		nick = modificationsTable.nickname,
		roles = modificationsTable.roles,
		mute = modificationsTable.mute,
		deaf = modificationsTable.deaf,
		channel_id = modificationsTable.channelId,
		communication_disabled_until = communication_disabled_until,
		flags = modificationsTable.flags
	}):await()
end

--[=[
	Creates a new DiscordGuildMember instance.

	@function new
	@param discordClient any -- The Discord client instance.
	@param userId string -- The ID of the user.
	@param guildId string -- The ID of the guild.
	@param memberData table -- The raw data for the guild member.
	@return DiscordGuildMember -- The newly created DiscordGuildMember instance.
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Interface.new(discordClient: any, userId: string, guildId: string, memberData: { [any]: any })
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordMember, `{guildId}-{userId}`, function()
		return Construct({
			discordClient = discordClient
		}, DiscordGuildMember.Prototype)
	end)

	if memberData.user then
		memberData.user = DiscordUser.new(self.discordClient, memberData.user)
	end

	memberData.guildId = guildId

	for index, value in memberData do
		self[index] = value
	end

	return self
end

export type DiscordGuildMember = typeof(DiscordGuildMember.Prototype) & {
	discordClient: any,
	user: DiscordUser.DiscordUser,
	guildId: number,
}

return DiscordGuildMember.Interface
