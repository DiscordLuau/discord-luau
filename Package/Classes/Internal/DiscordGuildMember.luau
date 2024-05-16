local Construct = require("../../Utils/Construct")

local DiscordEndpoints = require("../../Enums/DiscordEndpoints")

local CacheType = require("../../Enums/CacheType")

local Future = require("../../Vendor/Future")

local DiscordUser = require("DiscordUser")

--[=[
	@class Internal.DiscordGuildMember

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

function DiscordGuildMember.Prototype.banAsync(self: DiscordGuildMember, deleteMessagesSeconds: number?)
	return self.discordClient.discordGateway:deleteAsync(string.format(DiscordEndpoints.BotRemoveGuildMember, self.guildId, self.user.id)):await()
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