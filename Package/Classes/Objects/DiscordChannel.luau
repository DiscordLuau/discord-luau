local ChannelType = require("@Enums/ChannelType")

local GuildVoiceChannel = require("@Objects/GuildVoiceChannel")
local GuildTextChannel = require("@Objects/GuildTextChannel")
local UserDMChannel = require("@Objects/UserDMChannel")
local UserGroupChannel = require("@Objects/UserGroupChannel")
local GuildCategoryChannel = require("@Objects/GuildCategoryChannel")
local GuildAnnouncementChannel = require("@Objects/GuildAnnouncementChannel")
local GuildAnnouncementThreadChannel = require("@Objects/GuildAnnouncementThreadChannel")
local GuildPublicThreadChannel = require("@Objects/GuildPublicThreadChannel")
local GuildPrivateThreadChannel = require("@Objects/GuildPrivateThreadChannel")
local GuildStageVoiceChannel = require("@Objects/GuildStageVoiceChannel")
local GuildDirectoryChannel = require("@Objects/GuildDirectoryChannel")
local GuildForumChannel = require("@Objects/GuildForumChannel")
local GuildMediaChannel = require("@Objects/GuildMediaChannel")

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

		[any]: any,
	}
): DiscordChannel
	if rawChannelData.type == ChannelType.GuildTextChannel then
		return GuildTextChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.UserDMChannel then
		return UserDMChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildVoiceChannel then
		return GuildVoiceChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.UserGroupChannel then
		return UserGroupChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildCategory then
		return GuildCategoryChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildAnnouncement then
		return GuildAnnouncementChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildAnnouncementThread then
		return GuildAnnouncementThreadChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildPublicThread then
		return GuildPublicThreadChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildPrivateThread then
		return GuildPrivateThreadChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildStageVoiceChannel then
		return GuildStageVoiceChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildDirectory then
		return GuildDirectoryChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildForumChannel then
		return GuildForumChannel.new(discordClient, rawChannelData)
	elseif rawChannelData.type == ChannelType.GuildMediaChannel then
		return GuildMediaChannel.new(discordClient, rawChannelData)
	else
		error(`Unknown discord channel type '{rawChannelData.type}'`)
	end
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
