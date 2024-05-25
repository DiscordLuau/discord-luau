local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

--[=[
	@class Objects.DiscordComponent

	The `DiscordComponent` class represents a Discord emoji and provides a structure for emoji data.
]=]
local DiscordComponent = {}

DiscordComponent.Prototype = {}
DiscordComponent.Interface = {}

--[=[
	@prop type string
	@within Objects.DiscordComponent
	@readonly

	The type of the DiscordComponent. Default is "DiscordComponent".
]=]
DiscordComponent.Prototype.type = "DiscordComponent"

--[=[
	Creates a new DiscordComponent instance.

	@function new
	@param discordClient any -- The Discord client instance.
	@param emojiData table -- The raw data for the emoji.
	@return DiscordComponent -- The newly created DiscordComponent instance.
	@within Objects.DiscordComponent
]=]
function DiscordComponent.Interface.new(discordClient: any, emojiData: {}) end

export type DiscordComponent = typeof(DiscordComponent.Prototype) & {}

return DiscordComponent.Interface
