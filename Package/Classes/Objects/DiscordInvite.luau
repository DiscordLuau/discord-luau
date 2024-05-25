local Construct = require("../../Utils/Construct")

local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local CacheType = require("../../Enums/CacheType")

local Future = require("../../Vendor/Future")

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
	@return Future<unknown> -- A future that resolves when the invite is deleted.
	@within Objects.DiscordInvite
]=]
function DiscordInvite.Prototype.deleteAsync(self: DiscordInvite)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotDeleteInvite, self.code), {})
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
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordInvite, inviteData.code, function()
		return Construct({
			discordClient = discordClient,
		}, DiscordInvite.Prototype)
	end)

	if inviteData then
		for index, value in inviteData do
			self[index] = value
		end
	end

	return self
end

export type DiscordInvite = typeof(DiscordInvite.Prototype) & {
	discordClient: any,
	code: string,
}

return DiscordInvite.Interface
