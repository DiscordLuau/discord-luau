local Construct = require("../../Utils/Construct")

local DiscordIntentsBuilder = require("DiscordIntentsBuilder")

--[=[
	@class DiscordSettingsBuilder

	A simple class to retain some generic data before a Discord Client can be started, for instance:

	- The Discord bot token/authentication
	- The Discord bot intents

	Usage:
	```lua
	local DiscordLuau = require("../Submodules/DiscordLuau")

	local DiscordIntentsBuilder = DiscordLuau.DiscordIntentsBuilder.fromAll()
	local DiscordSettingsBuilder = DiscordLuau.DiscordSettingsBuilder.new("BOT TOKEN", DiscordIntentsBuilder)
	```
]=]
local DiscordSettingsBuilder = {}

DiscordSettingsBuilder.Interface = {}
DiscordSettingsBuilder.Prototype = {}

DiscordSettingsBuilder.Prototype.type = "DiscordSettingsBuilder"

--[=[
	Sets the Discord bot token.
	
	@method setDiscordToken
	@param discordToken string -- The token for the Discord bot.
	@within DiscordSettingsBuilder
	@return DiscordSettingsBuilder -- Returns the DiscordSettingsBuilder instance for method chaining.
]=]
function DiscordSettingsBuilder.Prototype.setDiscordToken(self: DiscordSettingsBuilder, discordToken: string)
	self.discordToken = discordToken

	return self
end

--[=[
	Sets the Discord bot intents.
	
	@method setIntents
	@param discordIntents DiscordIntentsBuilder -- The intents for the Discord bot.
	@within DiscordSettingsBuilder
	@return DiscordSettingsBuilder -- Returns the DiscordSettingsBuilder instance for method chaining.
]=]
function DiscordSettingsBuilder.Prototype.setIntents(self: DiscordSettingsBuilder, discordIntents: DiscordIntentsBuilder.DiscordIntentsBuilder)
	self.discordIntents = discordIntents

	return self
end

--[=[
	Constructs a new instance of DiscordSettingsBuilder.
	
	@function new
	@param discordToken string -- The token for the Discord bot.
	@param discordIntents DiscordIntentsBuilder? -- (Optional) The intents for the Discord bot. Defaults to `fromDefault` if not provided.
	@within DiscordSettingsBuilder
	@return DiscordSettingsBuilder -- A new instance of DiscordSettingsBuilder.
]=]
function DiscordSettingsBuilder.Interface.new(discordToken: string, discordIntents: DiscordIntentsBuilder.DiscordIntentsBuilder?)
	return Construct({
		discordToken = discordToken,
		discordIntents = discordIntents or DiscordIntentsBuilder.fromDefault(),
	}, DiscordSettingsBuilder.Prototype)
end

export type DiscordSettingsBuilder = typeof(DiscordSettingsBuilder.Interface.new(""))

return DiscordSettingsBuilder.Interface
