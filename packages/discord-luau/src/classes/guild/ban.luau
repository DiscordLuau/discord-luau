local construct = require("@util/construct")

local DiscordUser = require("@classes/user")

--[=[
	@class Objects.DiscordGuildBan

	The `DiscordGuildBan` class provides a way for developers to interact with guild bans.
]=]
local DiscordGuildBan = {}

DiscordGuildBan.Prototype = {}
DiscordGuildBan.Interface = {}

--[=[
	@prop type string
	@within Objects.DiscordGuildBan
	@readonly

	The type of the DiscordGuildBan. Default is "DiscordGuildBan".
]=]
DiscordGuildBan.Prototype.type = "DiscordGuildBan"

--[=[
	Creates a new DiscordGuildBan instance.

	@function new
	@return DiscordGuildBan
	@within Objects.DiscordGuildBan
]=]
function DiscordGuildBan.Interface.new(discordClient: any, discordBan: { [string]: any })
	--[=[
		@prop user Objects.DiscordUser
		@within Objects.DiscordGuildBan
	]=]

	--[=[
		@prop reason string?
		@within Objects.DiscordGuildBan
	]=]

	local self = construct({}, DiscordGuildBan.Prototype)

	if discordBan.user then
		discordBan.user = DiscordUser.new(discordClient, discordBan.user)
	end

	for key, value in discordBan do
		(self :: {})[key] = value
	end

	return self
end

export type DiscordGuildBan = typeof(DiscordGuildBan.Prototype) & {
	user: DiscordUser.DiscordUser,
	reason: string?,
}

return DiscordGuildBan.Interface
