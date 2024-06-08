local Construct = require("@Utils/Construct")

local IntentsBuilder = require("@Builders/IntentsBuilder")

--[=[
	@class Builders.SettingsBuilder

	A simple class to retain some generic data before a Discord Client can be started, for instance:

	- The Discord bot token/authentication
	- The Discord bot intents

	Usage:
	```lua
	local DiscordLuau = require("../Submodules/DiscordLuau")

	local IntentsBuilder = DiscordLuau.IntentsBuilder.fromAll()
	local SettingsBuilder = DiscordLuau.SettingsBuilder.new("BOT TOKEN", IntentsBuilder)
	```
]=]
local SettingsBuilder = {}

SettingsBuilder.Interface = {}
SettingsBuilder.Prototype = {}

SettingsBuilder.Prototype.type = "SettingsBuilder"

--[=[
	Sets the Discord bot token.
	
	@method setDiscordToken
	@param discordToken string -- The token for the Discord bot.
	@within Builders.SettingsBuilder
	@return Builders.SettingsBuilder -- Returns the SettingsBuilder instance for method chaining.
]=]
function SettingsBuilder.Prototype.setDiscordToken(self: SettingsBuilder, discordToken: string)
	self.discordToken = discordToken

	return self
end

--[=[
	Sets the Discord bot intents.
	
	@method setIntents
	@param discordIntents IntentsBuilder -- The intents for the Discord bot.
	@within Builders.SettingsBuilder
	@return Builders.SettingsBuilder -- Returns the SettingsBuilder instance for method chaining.
]=]
function SettingsBuilder.Prototype.setIntents(self: SettingsBuilder, discordIntents: IntentsBuilder.IntentsBuilder)
	self.discordIntents = discordIntents

	return self
end

--[=[
	Constructs a new instance of SettingsBuilder.
	
	@function new
	@param discordToken string -- The token for the Discord bot.
	@param discordIntents IntentsBuilder? -- (Optional) The intents for the Discord bot. Defaults to `fromDefault` if not provided.
	@within Builders.SettingsBuilder
	@return Builders.SettingsBuilder -- A new instance of SettingsBuilder.
]=]
function SettingsBuilder.Interface.new(discordToken: string, discordIntents: IntentsBuilder.IntentsBuilder?)
	return (
		Construct({
			discordToken = discordToken,
			discordIntents = discordIntents or IntentsBuilder.fromDefault(),
		}, SettingsBuilder.Prototype) :: unknown
	) :: SettingsBuilder
end

export type SettingsBuilder = typeof(SettingsBuilder.Prototype) & {
	discordToken: string,
	discordIntents: IntentsBuilder.IntentsBuilder,
}

return SettingsBuilder.Interface
