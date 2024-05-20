local Datetime = require("../../Std/Datetime")

local Construct = require("../../Utils/Construct")

local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local CacheType = require("../../Enums/CacheType")

local Future = require("../../Vendor/Future")

local DiscordUser = require("DiscordUser")

--[=[
	@class Objects.DiscordGuildMember

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordGuildMember = {}

DiscordGuildMember.Prototype = {}
DiscordGuildMember.Interface = {}

DiscordGuildMember.Prototype.type = "DiscordGuildMember"

function DiscordGuildMember.Prototype.kickAsync(self: DiscordGuildMember, deleteMessagesSeconds: number?)
	return self.discordClient.discordGateway:putAsync(string.format(DiscordEndpoints.BotBanGuildMember, self.guildId, self.user.id), {
		delete_message_seconds = deleteMessagesSeconds or 0
	}):await()
end

function DiscordGuildMember.Prototype.banAsync(self: DiscordGuildMember)
	return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotRemoveGuildMember, self.guildId, self.user.id)):await()
end

function DiscordGuildMember.Prototype.unbanAsync(self: DiscordGuildMember)
	return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotRemoveGuildMemberBan, self.guildId, self.user.id)):await()
end

function DiscordGuildMember.Prototype.addRoleAsync(self: DiscordGuildMember, roleId: string)
	return self.discordClient.discordGateway:putAsync(string.format(DiscordEndpoints.BotAddGuildMemberRole, self.guildId, self.user.id, roleId)):await()
end

function DiscordGuildMember.Prototype.removeRoleAsync(self: DiscordGuildMember, roleId: string)
	return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotRemoveGuildMemberRole, self.guildId, self.user.id, roleId)):await()
end

function DiscordGuildMember.Prototype.timeoutAsync(self: DiscordGuildMember, seconds: number)
	return self:modifyAsync({
		timeoutUntil = seconds,
	})
end

function DiscordGuildMember.Prototype.muteAsync(self: DiscordGuildMember)
	return self:modifyAsync({
		mute = true,
	})
end

function DiscordGuildMember.Prototype.unmuteAsync(self: DiscordGuildMember)
	return self:modifyAsync({
		mute = false,
	})
end

function DiscordGuildMember.Prototype.deafenAsync(self: DiscordGuildMember)
	return self:modifyAsync({
		deaf = true,
	})
end

function DiscordGuildMember.Prototype.undeafenAsync(self: DiscordGuildMember)
	return self:modifyAsync({
		deaf = false,
	})
end

function DiscordGuildMember.Prototype.setNicknameAsync(self: DiscordGuildMember, nickname: string)
	return self:modifyAsync({
		nickname = nickname,
	})
end

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