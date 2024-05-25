local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")
local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local Future = require("../../Vendor/Future")

local DiscordWebsocket = require("../Network/DiscordWebsocket")
local DiscordVoiceConnection = require("../Network/DiscordVoiceConnection")

--[=[
	@class Objects.DiscordVoiceChannel

	DiscordVoiceChannel represents a voice channel in a Discord server, providing methods to connect, disconnect, and modify the channel.
]=]
local DiscordVoiceChannel = {}

DiscordVoiceChannel.Prototype = {}
DiscordVoiceChannel.Interface = {}

DiscordVoiceChannel.Prototype.type = "DiscordVoiceChannel"

--[=[
	Connects to the voice channel asynchronously.
	
	@method connectAsync
	@within Objects.DiscordVoiceChannel
	@return Future<boolean> -- A future that resolves to a boolean indicating success.
]=]
function DiscordVoiceChannel.Prototype.connectAsync(self: DiscordVoiceChannel): Future.Future<boolean>
	return Future.try(function(): boolean
		self.voiceConnection = DiscordVoiceConnection.new(self.discordClient, `voice-{self.id}`)

		return self.voiceConnection:connectAsync(self.guildId, self.id):await()
	end)
end

--[=[
	Disconnects from the voice channel asynchronously.
	
	@method disconnectAsync
	@within Objects.DiscordVoiceChannel
	@return Future<unknown> -- A future that resolves when the disconnection is complete.
]=]
function DiscordVoiceChannel.Prototype.disconnectAsync(self: DiscordVoiceChannel): Future.Future<unknown>
	return Future.try(function()
		return self.voiceConnection:disconnectAsync():await()
	end)
end

--[=[
	Modifies the voice channel settings asynchronously.
	
	@method modifyAsync
	@param channelSchema DiscordVoiceChannelSchema -- The schema containing the modifications to be applied.
	@within Objects.DiscordVoiceChannel
	@return Future<unknown> -- A future that resolves when the modifications are complete.
]=]
function DiscordVoiceChannel.Prototype.modifyAsync(self: DiscordVoiceChannel, channelSchema: DiscordVoiceChannelSchema)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(string.format(DiscordEndpoints.BotModifyChannel, self.id), {
				video_quality_mode = channelSchema.videoQualityMode,
				rtc_region = channelSchema.rtcRegion,
				parent_id = channelSchema.parentId,
				user_limit = channelSchema.userLimit,
				bitrate = channelSchema.bitrate,
				rate_limit_per_user = channelSchema.rateLimitPerUser,
				nsfw = channelSchema.nsfw,
				position = channelSchema.position,
				name = channelSchema.name,
			})
			:await()
	end)
end

--[=[
	Creates a new instance of DiscordVoiceChannel.
	
	@function new
	@param discordClient any -- The Discord client instance.
	@param channelData table -- The data for the channel to be created.
	@within Objects.DiscordVoiceChannel
	@return DiscordVoiceChannel -- A new instance of DiscordVoiceChannel.
]=]
function DiscordVoiceChannel.Interface.new(
	discordClient: any,
	channelData: {
		id: string,
		recipients: { unknown },
	}
): DiscordVoiceChannel
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordVoiceChannel, channelData.id, function()
		return Construct({
			id = channelData.id,

			discordClient = discordClient,
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
	discordClient: any,

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
	voiceConnection: DiscordVoiceConnection.DiscordVoiceConnection,
}

export type DiscordVoiceChannelSchema = {
	videoQualityMode: number,
	rtcRegion: string,
	parentId: string,
	userLimit: number,
	bitrate: number,
	rateLimitPerUser: number,
	nsfw: boolean,
	position: number,
	name: string,
}

return DiscordVoiceChannel.Interface
