local construct = require("@util/construct")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.DiscordUser

	DiscordUser represents a user on Discord, encapsulating user data such as username, avatar, and various flags.
]=]

--[=[
	@prop username string
	@within Objects.DiscordUser
]=]

--[=[
	@prop flags string
	@within Objects.DiscordUser
]=]

--[=[
	@prop mfaEnabled boolean
	@within Objects.DiscordUser
]=]

--[=[
	@prop avatar string
	@within Objects.DiscordUser
]=]

--[=[
	@prop id string
	@within Objects.DiscordUser
]=]

--[=[
	@prop bot boolean
	@within Objects.DiscordUser
]=]

--[=[
	@prop verified boolean
	@within Objects.DiscordUser
]=]

--[=[
	@prop discriminator string
	@within Objects.DiscordUser
]=]

local DiscordUser = {}

DiscordUser.Prototype = {}
DiscordUser.Interface = {}

DiscordUser.Prototype.type = "DiscordUser"

--[=[
	Creates a new instance of DiscordUser.
	
	@function new
	@param discordClient any -- The Discord client instance.
	@param partialUserData table -- Partial data for the user to be created.
	@within Objects.DiscordUser
	@return DiscordUser -- A new instance of DiscordUser.
]=]
function DiscordUser.Interface.new(
	discordClient: any,
	partialUserData: {
		username: string?,
		flags: number?,
		mfaEnabled: boolean?,
		avatar: string?,
		id: string,
		bot: boolean?,
		verified: boolean?,
		discriminator: string?,
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordUser, partialUserData.id, function()
		return construct({
			id = partialUserData.id,

			discordClient = discordClient,
		}, DiscordUser.Prototype)
	end)

	if partialUserData then
		for index, value in partialUserData do
			self[index] = value
		end
	end

	return self
end

export type DiscordUser = typeof(DiscordUser.Prototype) & {
	username: string?,
	flags: string?,
	mfaEnabled: boolean?,
	avatar: string?,
	id: string,
	bot: boolean?,
	verified: boolean?,
	discriminator: string?,
}

return DiscordUser.Interface
