local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local ChannelType = require("../../Enums/ChannelType")

local Future = require("../../Vendor/Future")

local DiscordMessage = require("../Objects/DiscordMessage")

local MessageBuilder = require("../Builders/MessageBuilder")
local PermissionsBuilder = require("../Builders/PermissionsBuilder")

local GuildVoiceChannel = require("GuildVoiceChannel")
local GuildTextChannel = require("GuildTextChannel")
local UserDMChannel = require("UserDMChannel")
local UserGroupChannel = require("UserGroupChannel")
local GuildCategoryChannel = require("GuildCategoryChannel")
local GuildAnnouncementChannel = require("GuildAnnouncementChannel")
local GuildAnnouncementThreadChannel = require("GuildAnnouncementThreadChannel")
local GuildPublicThreadChannel = require("GuildPublicThreadChannel")
local GuildPrivateThreadChannel = require("GuildPrivateThreadChannel")
local GuildStageVoiceChannel = require("GuildStageVoiceChannel")
local GuildDirectoryChannel = require("GuildDirectoryChannel")
local GuildForumChannel = require("GuildForumChannel")
local GuildMediaChannel = require("GuildMediaChannel")

--[=[
	@class Objects.DiscordChannel

	The `DiscordChannel` class represents a generic Discord channel and provides various methods to interact with and manage the channel.
]=]
local DiscordChannel = {}

DiscordChannel.Prototype = {}
DiscordChannel.Interface = {}

function DiscordChannel.Interface.from(
	discordClient: any,
	rawChannelData: {
		id: string,
		type: number,

		[string]: any,
	}
)
	local baseChannelObject: DiscordChannel

	if rawChannelData.type == ChannelType.GuildTextChannel then
		baseChannelObject = GuildTextChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.UserDMChannel then
		baseChannelObject = UserDMChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildVoiceChannel then
		baseChannelObject = GuildVoiceChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.UserGroupChannel then
		baseChannelObject = UserGroupChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildCategory then
		baseChannelObject = GuildCategoryChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildAnnouncement then
		baseChannelObject = GuildAnnouncementChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildAnnouncementThread then
		baseChannelObject = GuildAnnouncementThreadChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildPublicThread then
		baseChannelObject = GuildPublicThreadChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildPrivateThread then
		baseChannelObject = GuildPrivateThreadChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildStageVoiceChannel then
		baseChannelObject = GuildStageVoiceChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildDirectory then
		baseChannelObject = GuildDirectoryChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildForumChannel then
		baseChannelObject = GuildForumChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildMediaChannel then
		baseChannelObject = GuildMediaChannel.new(discordClient, rawChannelData)
	else
		error(`Unknown discord channel type '{rawChannelData.type}'`)
	end

	return baseChannelObject
end

export type DiscordChannel =
	GuildTextChannel.GuildTextChannel
	| UserDMChannel.UserDMChannel
	| GuildVoiceChannel.GuildVoiceChannel
	| UserGroupChannel.UserGroupChannel
	| GuildCategoryChannel.GuildCategoryChannel
	| GuildAnnouncementChannel.GuildAnnouncementChannel
	| GuildAnnouncementThreadChannel.GuildAnnouncementThreadChannel
	| GuildPublicThreadChannel.GuildPublicThreadChannel
	| GuildPrivateThreadChannel.GuildPrivateThreadChannel
	| GuildStageVoiceChannel.GuildStageVoiceChannel
	| GuildDirectoryChannel.GuildDirectoryChannel
	| GuildForumChannel.GuildForumChannel
	| GuildMediaChannel.GuildMediaChannel

return DiscordChannel.Interface
