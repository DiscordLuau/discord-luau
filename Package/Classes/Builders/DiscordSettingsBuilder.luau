local Construct = require("../../Utils/Construct")

local DiscordIntentsBuilder = require("DiscordIntentsBuilder")

--[=[
	@class DiscordSettingsBuilder

	A simple class to retain some generic data before a Discord Client can be started, for inst;

	- The discord bot Token/Authentication
	- The discord bot Intents

	```lua
		local DiscordLuau = require("../Submodules/DiscordLuau")

		local DiscordIntentsBuilder = DiscordLuau.DiscordIntentsBuilder.fromAll()
		local DiscordSettingsBuilder = DiscordLuau.DiscordSettingsBuilder.new("BOT TOKEN", DiscordIntentsBuilder)

		...
	```
]=]
local DiscordSettingsBuilder = {}

DiscordSettingsBuilder.Interface = {}
DiscordSettingsBuilder.Prototype = {}

DiscordSettingsBuilder.Prototype.type = "DiscordSettingsBuilder"

--[=[
	@method setDiscordToken
	@within DiscordSettingsBuilder

	@param discordToken string

	@return DiscordSettingsBuilder

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordSettingsBuilder.Prototype.setDiscordToken(self: DiscordSettingsBuilder, discordToken: string)
	self.discordToken = discordToken

	return self
end

--[=[
	@method setIntents
	@within DiscordSettingsBuilder

	@param discordIntents !DiscordIntentsBuilder

	@return DiscordSettingsBuilder

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordSettingsBuilder.Prototype.setIntents(self: DiscordSettingsBuilder, discordIntents: DiscordIntentsBuilder.DiscordIntentsBuilder)
	self.discordIntents = discordIntents

	return self
end

--[=[
	@function new
	@within DiscordSettingsBuilder

	@param discordToken string
	@param discordIntents !DiscordIntentsBuilder
	
	@return DiscordSettingsBuilder

	(yet-to-do!)

	```lua
		
	```
]=]
function DiscordSettingsBuilder.Interface.new(discordToken: string, discordIntents: DiscordIntentsBuilder.DiscordIntentsBuilder?)
	return Construct({
		discordToken = discordToken,
		discordIntents = discordIntents or DiscordIntentsBuilder.fromDefault(),
	}, DiscordSettingsBuilder.Prototype)
end

export type DiscordSettingsBuilder = typeof(DiscordSettingsBuilder.Interface.new(""))

return DiscordSettingsBuilder.Interface