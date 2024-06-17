local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")

local DiscordUser = require("@Objects/DiscordUser")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.DiscordInvite

	DiscordInvite represents an invite link to a Discord server, providing methods to delete the invite.
]=]
local DiscordInvite = {}

DiscordInvite.Prototype = {}
DiscordInvite.Interface = {}

DiscordInvite.Prototype.type = "DiscordInvite"

--[=[
	Deletes the invite asynchronously.
	
	@method deleteAsync
	@return Vendor.Future<unknown> -- A future that resolves when the invite is deleted.
	@within Objects.DiscordInvite
]=]
function DiscordInvite.Prototype.deleteAsync(self: DiscordInvite)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotDeleteInvite, self.code))
			:await()
	end)
end

--[=[
	Creates a new instance of DiscordInvite.
	
	@function new
	@param discordClient any -- The Discord client instance.
	@param inviteData table -- The data for the invite to be created.
	@return DiscordInvite -- A new instance of DiscordInvite.
	@within Objects.DiscordInvite
]=]
function DiscordInvite.Interface.new(
	discordClient: any,
	inviteData: {
		code: string,

		[string]: any,
	}
)
	--[=[
		@prop code string
		@within Objects.DiscordInvite
	]=]

	--[=[
		@prop type number
		@within Objects.DiscordInvite
	]=]

	--[=[
		@prop guild { id: string, name: string, }?
		@within Objects.DiscordInvite
	]=]

	--[=[
		@prop inviter Objects.DiscordUser?
		@within Objects.DiscordInvite
	]=]

	--[=[
		@prop targetType number
		@within Objects.DiscordInvite
	]=]

	--[=[
		@prop targetUser Objects.DiscordUser?
		@within Objects.DiscordInvite
	]=]

	--[=[
		@prop targetApplication { id: string, }?
		@within Objects.DiscordInvite
	]=]

	local self = discordClient.discordCache:getDataOr(CacheType.DiscordInvite, inviteData.code, function()
		return Construct({
			discordClient = discordClient,
		}, DiscordInvite.Prototype)
	end)

	if inviteData then
		if inviteData.inviter then
			inviteData.inviter = DiscordUser.new(discordClient, inviteData.inviter)
		end

		if inviteData.targetUser then
			inviteData.targetUser = DiscordUser.new(discordClient, inviteData.targetUser)
		end

		for index, value in inviteData do
			self[index] = value
		end
	end

	return self
end

export type DiscordInvite = typeof(DiscordInvite.Prototype) & {
	discordClient: any,
	code: string,
	type: number,
	guild: {
		id: string,
		name: string,
	}?,
	inviter: DiscordUser.DiscordUser?,
	targetType: number,
	targetUser: DiscordUser.DiscordUser?,
	targetApplication: {
		id: string,
	}?,
}

return DiscordInvite.Interface
