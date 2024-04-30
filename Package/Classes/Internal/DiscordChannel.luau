local DiscordTextChannel = require("DiscordTextChannel")
local DiscordVoiceChannel = require("DiscordVoiceChannel")

--[=[
	@class Internal.DiscordChannel

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordChannel = {}

DiscordChannel.Prototype = {}
DiscordChannel.Interface = {}

function DiscordChannel.Interface.new(discordClient: any, rawChannelData: any)
	-- https://discord.com/developers/docs/resources/channel#channel-object-channel-types
	-- todo: support other channel types lol

	if rawChannelData.type == 0 then
		return DiscordTextChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == 2 then
		return DiscordVoiceChannel.new(discordClient, rawChannelData)
	else
		return rawChannelData
	end
end

return DiscordChannel.Interface