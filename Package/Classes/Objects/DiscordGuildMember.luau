local Construct = require("@Utils/Construct")

local Resolvable = require("@Network/Resolvable")

local DiscordUser = require("@Objects/DiscordUser")

local MemberBuilder = require("@Builders/MemberBuilder")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

local ResolvableType = require("@Enums/ResolvableType")
local CacheType = require("@Enums/CacheType")

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
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.kickAsync(self: DiscordGuildMember, deleteMessagesSeconds: number?)
	return self.discordClient.discordGateway
		:putAsync(
			string.format(DiscordEndpoints.BotRemoveGuildMember, self.guildId, self.user.id),
			Resolvable.new(ResolvableType.JSON, {
				delete_message_seconds = deleteMessagesSeconds or 0,
			})
		)
		:await()
end

--[=[
	Bans the guild member asynchronously.

	@method banAsync
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.banAsync(self: DiscordGuildMember)
	return self.discordClient.discordGateway
		:deleteAsync(string.format(DiscordEndpoints.BotBanGuildMember, self.guildId, self.user.id))
		:await()
end

--[=[
	Unbans the guild member asynchronously.

	@method unbanAsync
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.unbanAsync(self: DiscordGuildMember)
	return self.discordClient.discordGateway
		:deleteAsync(string.format(DiscordEndpoints.BotRemoveGuildMemberBan, self.guildId, self.user.id))
		:await()
end

--[=[
	Adds a role to the guild member asynchronously.

	@method addRoleAsync
	@param roleId string -- The ID of the role to add.
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.addRoleAsync(self: DiscordGuildMember, roleId: string)
	return self.discordClient.discordGateway
		:putAsync(string.format(DiscordEndpoints.BotAddGuildMemberRole, self.guildId, self.user.id, roleId))
		:await()
end

--[=[
	Removes a role from the guild member asynchronously.

	@method removeRoleAsync
	@param roleId string -- The ID of the role to remove.
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.removeRoleAsync(self: DiscordGuildMember, roleId: string)
	return self.discordClient.discordGateway
		:deleteAsync(string.format(DiscordEndpoints.BotRemoveGuildMemberRole, self.guildId, self.user.id, roleId))
		:await()
end

--[=[
	Times out the guild member asynchronously.

	@method timeoutAsync
	@param seconds number -- The duration of the timeout in seconds.
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.timeoutAsync(self: DiscordGuildMember, seconds: number)
	return self:modifyAsync(MemberBuilder.new():setTimeoutFor(seconds))
end

--[=[
	Mutes the guild member asynchronously.

	@method muteAsync
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.muteAsync(self: DiscordGuildMember)
	return self:modifyAsync(MemberBuilder.new():setMuted(true))
end

--[=[
	Unmutes the guild member asynchronously.

	@method unmuteAsync
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.unmuteAsync(self: DiscordGuildMember)
	return self:modifyAsync(MemberBuilder.new():setMuted(false))
end

--[=[
	Deafens the guild member asynchronously.

	@method deafenAsync
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.deafenAsync(self: DiscordGuildMember)
	return self:modifyAsync(MemberBuilder.new():setDeafened(true))
end

--[=[
	Undeafens the guild member asynchronously.

	@method undeafenAsync
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.undeafenAsync(self: DiscordGuildMember)
	return self:modifyAsync(MemberBuilder.new():setDeafened(false))
end

--[=[
	Sets the nickname of the guild member asynchronously.

	@method setNicknameAsync
	@param nickname string -- The new nickname.
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.setNicknameAsync(self: DiscordGuildMember, nickname: string)
	return self:modifyAsync(MemberBuilder.new():setNickname(nickname))
end

--[=[
	Modifies the guild member asynchronously.

	@method modifyAsync
	@param memberBuilder Builders.MemberBuilder
	@return Vendor.Future
	@within Objects.DiscordGuildMember
]=]
function DiscordGuildMember.Prototype.modifyAsync(self: DiscordGuildMember, memberBuilder: MemberBuilder.MemberBuilder)
	return self.discordClient.discordGateway
		:patchAsync(
			string.format(DiscordEndpoints.BotModifyGuildMember, self.guildId, self.user.id),
			memberBuilder:toPayloadObject()
		)
		:await()
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
function DiscordGuildMember.Interface.new(
	discordClient: any,
	userId: string,
	guildId: string,
	memberData: { [any]: any }
)
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordMember, `{guildId}-{userId}`, function()
		return Construct({
			discordClient = discordClient,
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
