local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local DiscordVoiceConnection = require("@Network/DiscordVoiceConnection")

local BaseDiscordGuildChannel = require("@Objects/BaseDiscordGuildChannel")

--[=[
	@class Objects.BaseGuildVoiceChannel

	A base discord voice channel, every Guild Voice channel extends from.

	@tag inherit Objects.BaseDiscordGuildChannel
]=]
local BaseGuildVoiceChannel = {}

BaseGuildVoiceChannel.Prototype = {}
BaseGuildVoiceChannel.Interface = {}

BaseGuildVoiceChannel.Prototype.type = "BaseGuildVoiceChannel"

--[=[
	Connects to the voice channel asynchronously.
	
	@method connectAsync
	@within Objects.BaseGuildVoiceChannel
	@return Vendor.Future<boolean> -- A future that resolves to a boolean indicating success.
]=]
function BaseGuildVoiceChannel.Prototype.connectAsync(self: BaseGuildVoiceChannel)
	return Future.try(function()
		local connection = DiscordVoiceConnection.new(self.discordClient, `voice-{self.id}`)

		self.voiceConnection = connection

		return connection:connectAsync(self.guildId, self.id):await()
	end)
end

--[=[
	Disconnects from the voice channel asynchronously.
	
	@method disconnectAsync
	@within Objects.BaseGuildVoiceChannel
	@return Vendor.Future<unknown> -- A future that resolves when the disconnection is complete.
]=]
function BaseGuildVoiceChannel.Prototype.disconnectAsync(self: BaseGuildVoiceChannel): Future.Future<unknown>
	return Future.try(function()
		if not self.voiceConnection then
			return
		end

		return self.voiceConnection:disconnectAsync():await()
	end)
end

function BaseGuildVoiceChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
		guildId: string,
	}
)
	--[=[
		@prop id string
		@within Objects.DiscordApplication
	]=]

	--[=[
		@prop guildId string
		@within Objects.DiscordApplication
	]=]

	--[=[
		@prop voiceConnection Network.DiscordVoiceConnection?
		@within Objects.DiscordApplication
	]=]

	--[=[
		@prop bitrate number
		@within Objects.DiscordApplication
	]=]

	--[=[
		@prop userLimit number
		@within Objects.DiscordApplication
	]=]

	--[=[
		@prop rtcRegion string
		@within Objects.DiscordApplication
	]=]

	--[=[
		@prop videoQualityMode number
		@within Objects.DiscordApplication
	]=]
	local channelObject = Construct({
		discordClient = discordClient,
	}, BaseGuildVoiceChannel.Prototype)

	for index, value in channelData do
		(channelObject :: {})[index] = value
	end

	return Extend(channelObject, BaseDiscordGuildChannel.new(discordClient, channelData))
end

export type BaseGuildVoiceChannel =
	BaseDiscordGuildChannel.BaseDiscordGuildChannel
	& typeof(BaseGuildVoiceChannel.Prototype)
	& {
		id: string,
		guildId: string,

		voiceConnection: DiscordVoiceConnection.DiscordVoiceConnection?,

		bitrate: number,
		userLimit: number,

		rtcRegion: string,
		videoQualityMode: number,
	}

return BaseGuildVoiceChannel.Interface
