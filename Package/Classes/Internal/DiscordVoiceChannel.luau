local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

local Future = require("../../Vendor/Future")

local DiscordWebsocket = require("../Network/DiscordWebsocket")
local DiscordVoiceConnection = require("../Network/DiscordVoiceConnection")

--[=[
	@class Internal.DiscordVoiceChannel

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordVoiceChannel = {}

DiscordVoiceChannel.Prototype = {}
DiscordVoiceChannel.Interface = {}

DiscordVoiceChannel.Prototype.type = "DiscordVoiceChannel"

function DiscordVoiceChannel.Prototype.connectAsync(self: DiscordVoiceChannel): Future.Future<unknown>
	return Future.try(function()
		-- self.voiceConnection = DiscordVoiceConnection.new(self.discordClient, `voice-{self.id}`)

		self.discordClient.reporter:debug(`Voice Chat isn't a functional feature in discord-luau!`)

		-- return self.voiceConnection:connectAsync(
		-- 	self.guildId,
		-- 	self.id
		-- ):await()
	end)
end

function DiscordVoiceChannel.Prototype.disconnectAsync(self: DiscordVoiceChannel): Future.Future<unknown>
	return Future.try(function()
		-- return self.voiceConnection:disconnectAsync():await()
	end)
end

function DiscordVoiceChannel.Interface.new(discordClient: any, channelData: {
	id: string,
	recipients: { unknown },
}): DiscordVoiceChannel
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordVoiceChannel, channelData.id, function()
		return Construct({
			id = channelData.id,
	
			discordClient = discordClient
		}, DiscordVoiceChannel.Prototype)
	end)

	if channelData then
		for index, value in channelData do
			if self[index] ~= nil then
				continue
			end

			self[index] = value
		end
	end

	return self
end

export type DiscordVoiceChannel = typeof(DiscordVoiceChannel.Prototype) & {
	type: number,
	nsfw: boolean,
	id: string,
	flags: number,
	name: string,
	position: number,
	rateLimitPerUser: number,
	lastMessageId: string,
	guildId: string,

	voiceWebsocket: DiscordWebsocket.DiscordWebsocket,
	voiceConnection: DiscordVoiceConnection.DiscordVoiceConnection
}

return DiscordVoiceChannel.Interface