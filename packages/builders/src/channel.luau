--[[
	Implementation of a discord Channel as a luau builder.	

	https://discord.com/developers/docs/resources/guild#create-guild-channel
]]

local apiTypes = require("../lune_packages/api_types")

local util = require("../lune_packages/util")

local GUILD_CHANNEL_TYPE_MAP = {
	["GuildText"] = 0,
	["Dm"] = 1,
	["GuildVoice"] = 2,
	["GroupDm"] = 3,
	["GuildCategory"] = 4,
	["GuildAnnouncement"] = 5,
	["AnnouncementThread"] = 10,
	["PublicThread"] = 11,
	["PrivateThread"] = 12,
	["GuildStageVoice"] = 13,
	["GuildDirectory"] = 14,
	["GuildForum"] = 15,
	["GuildMedia"] = 16,
}

local GUILD_VIDEO_QUALITY_MODE_MAP = {
	["Auto"] = 1,
	["Full"] = 2,
}

local GUILD_SORT_ORDER_MAP = {
	["LatestActivity"] = 0,
	["CreationDate"] = 1,
}

local GUILD_FORUM_LAYOUT_MAP = {
	["NotSet"] = 0,
	["ListView"] = 1,
	["GalleryView"] = 2,
}

local Channel = {}

Channel.Prototype = {}
Channel.Interface = {}

--[[
	Set the name of this Channel
]]
function Channel.Prototype.setName(self: Channel, tagName: string): Channel
	assert(#tagName <= 100, `Channel name must be less than 100 characters.`)
	assert(#tagName > 1, `Channel name must be more than 1 characters.`)

	assert(util.validateKebabCase(tagName), `Channel name must be kebab-case.`)

	self.name = tagName

	return self
end

--[[
	Set the Type of channel this is.
]]
function Channel.Prototype.setType(self: Channel, channelType: apiTypes.ChannelType): Channel
	self.type = channelType

	return self
end

--[[
	Sets the position of the channel in the discord channels list.

	channels with the same position are sorted by id
]]
function Channel.Prototype.setPosition(self: Channel, channelPosition: number): Channel
	self.position = channelPosition

	return self
end

--[[
	Adds an overwrite object to the channel's permission overwrites.

	channel overwrites are responsible for handling user/role permission on a specific channel.
]]
function Channel.Prototype.setOverwrites(self: Channel, overwriteObjects: { apiTypes.OverwriteObject }): Channel
	self.permissionOverwrites = overwriteObjects

	return self
end

--[[
	Sets the channels topic, topics appear at the top of the discord app and help to inform players about
		the channel's purpose.
]]
function Channel.Prototype.setTopic(self: Channel, channelTopic: string): Channel
	assert(
		self.type == "GuildText"
			or self.type == "GuildAnnouncement"
			or self.type == "GuildForum"
			or self.type == "GuildMedia",
		`Channel topic is only supported for guild text, announcement, forum, and media channels.`
	)

	assert(#channelTopic <= 1024, `Channel topic must be less than 1024 characters.`)
	assert(#channelTopic > 0, `Channel topic must be more than 0 characters.`)

	self.topic = channelTopic

	return self
end

--[[
	Sets the bitrate of the voice channel, the bitrate (in bits) of the voice or stage channel.
]]
function Channel.Prototype.setBitrate(self: Channel, bitrate: number): Channel
	assert(
		self.type == "GuildVoice" or self.type == "GuildStageVoice",
		`Channel bitrate is only supported for guild voice and stage voice channels.`
	)

	assert(bitrate < 96000, `Channel bitrate must be less than 96kbit/s.`)
	assert(bitrate > 8000, `Channel bitrate must be more than 8kbit/s.`)

	self.bitrate = bitrate

	return self
end

--[[
	the user limit of the voice channel	

	the user limit of a voice channel is the maximum number of users allowed in the channel at one time.
]]
function Channel.Prototype.setUserLimit(self: Channel, userLimit: number?): Channel
	assert(
		self.type == "GuildVoice" or self.type == "GuildStageVoice",
		`Channel user limit is only supported for guild voice and stage voice channels.`
	)

	self.userLimit = userLimit

	return self
end

--[[
	amount of seconds a user has to wait before sending another message; bots, as well as users with
		the permission manage_messages or manage_channel, are unaffected
]]
function Channel.Prototype.setRateLimitPerUser(self: Channel, rateLimitPerUser: number?): Channel
	assert(
		self.type == "GuildText"
			or self.type == "GuildVoice"
			or self.type == "GuildStageVoice"
			or self.type == "GuildForum"
			or self.type == "GuildMedia",
		`Channel rate limit per user is only supported for guild text, voice, stage voice, forum, and media channels.`
	)

	assert(rateLimitPerUser <= 21600, `Channel rate limit per user must be less than 21600 seconds.`)
	assert(rateLimitPerUser >= 0, `Channel rate limit per user must be more than 0 seconds.`)

	self.rateLimitPerUser = rateLimitPerUser

	return self
end

--[[
	set the parent of the channel, channel parents are categories and can help break down a discord guild.
]]
function Channel.Prototype.setParentId(self: Channel, parentId: apiTypes.Snowflake?): Channel
	assert(
		self.type == "GuildText"
			or self.type == "GuildVoice"
			or self.type == "GuildAnnouncement"
			or self.type == "GuildStageVoice"
			or self.type == "GuildForum"
			or self.type == "GuildMedia",
		`Channel parent id is only supported for guild text, announcement, voice, stage voice, forum, and media channels.`
	)

	self.parentId = parentId

	return self
end

--[[
	set weather this channel is NSFW or not.
]]
function Channel.Prototype.setNSFW(self: Channel, isNSFW: boolean): Channel
	assert(
		self.type == "GuildText"
			or self.type == "GuildVoice"
			or self.type == "GuildAnnouncement"
			or self.type == "GuildStageVoice"
			or self.type == "GuildForum",
		`Channel nsfw is only supported for guild text, announcement, voice, stage voice and forum channels.`
	)

	self.nsfw = isNSFW

	return self
end

--[[
	set the voice region (requires you to query for the voice region ids) of the voice channel.

	voice regions are regions that discord uses to host voice channels.
]]
function Channel.Prototype.setVoiceRegion(self: Channel, voiceRegionId: string): Channel
	assert(
		self.type == "GuildVoice" or self.type == "GuildStageVoice",
		`Channel voice region is only supported for voice and stage voice.`
	)

	self.rtcRegion = voiceRegionId

	return self
end

--[[
	sets the video quality mode of the voice channel.
]]
function Channel.Prototype.setVideoQualityMode(self: Channel, videoQualityMode: apiTypes.VideoQualityMode): Channel
	assert(
		self.type == "GuildVoice" or self.type == "GuildStageVoice",
		`Channel video quality mode is only supported for voice and stage voice.`
	)

	self.videoQualityMode = videoQualityMode

	return self
end

--[[
	sets the default auto archive duration for the channel, the default duration that the clients use (not the API)
		for newly created threads in the channel, in minutes, to automatically archive the thread after recent activity	
]]
function Channel.Prototype.setDefaultAutoArchiveDuration(self: Channel, autoArchiveDuration: number): Channel
	assert(
		self.type == "GuildText"
			or self.type == "GuildAnnouncement"
			or self.type == "GuildForum"
			or self.type == "GuildMedia",
		`Channel auto archive duration is only supported for guild text, announcement, forum, and media channels.`
	)

	self.defaultAutoArchiveDuration = autoArchiveDuration

	return self
end

--[[
	sets the default reaction emoji for either a forum or media channel.

	This is the default emoji that the channel will use for the forum or media channel.
]]
function Channel.Prototype.setDefaultReactionEmoji(
	self: Channel,
	defaultReactionEmoji: apiTypes.DefaultReactionObject
): Channel
	assert(
		self.type == "GuildForum" or self.type == "GuildMedia",
		`Channel default reaction is only supported for forum, and media channels.`
	)

	self.defaultReactionEmoji = defaultReactionEmoji

	return self
end

--[[
	specify channel forum tags that are available to the channel.

	This is the list of tags that the channel will use for the forum.
]]
function Channel.Prototype.setForumTags(self: Channel, forumTags: { apiTypes.ForumTagObject }): Channel
	assert(
		self.type == "GuildForum" or self.type == "GuildMedia",
		`Channel forum tags are only supported for forum, and media channels.`
	)

	self.availableTags = forumTags

	return self
end

--[[
	sets the default sort order for the channel.

	This is the sort order that the channel will use for newly created threads.
]]
function Channel.Prototype.setDefaultSortOrder(self: Channel, sortOrder: apiTypes.ForumSortOrder): Channel
	assert(
		self.type == "GuildForum" or self.type == "GuildMedia",
		`Channel sort order is only supported for forum, and media channels.`
	)

	self.defaultSortOrder = sortOrder

	return self
end

--[[
	sets the default forum layout for the channel.

	This is the layout that the channel will use for newly created threads.
]]
function Channel.Prototype.setDefaultForumLayout(self: Channel, forumLayout: apiTypes.ForumLayout): Channel
	assert(self.type == "GuildForum", `Channel forum layout is only supported for forum channels.`)

	self.defaultForumLayout = forumLayout

	return self
end

--[[
	sets the default thread rate limit per user for the channel.

	This is the amount of seconds a user has to wait before sending another message in the thread,
]]
function Channel.Prototype.setDefaultThreadRateLimitPerUser(self: Channel, threadRateLimitPerUser: number): Channel
	assert(
		self.type == "GuildText"
			or self.type == "GuildAnnouncement"
			or self.type == "GuildForum"
			or self.type == "GuildMedia",
		`Channel default thread rate limit per user is only supported for forum channels.`
	)

	self.defaultThreadRateLimitPerUser = threadRateLimitPerUser

	return self
end

--[[
	Sets the channel flags using a bitfield value.

	The flags control various channel settings and behaviors.
]]
function Channel.Prototype.setFlags(self: Channel, bitflags: number): Channel
	self.flags = bitflags

	return self
end

--[[
	Sets the channel icon using the provided icon data.

	The icon data should be a base64 encoded image string.
]]
function Channel.Prototype.setIcon(self: Channel, iconData: string): Channel
	self.icon = iconData

	return self
end
--[[
	Responsible for buillding the channel object that the Discord API can understand.
]]
function Channel.Prototype.build(self: Channel): JSON
	return {
		id = self.id,

		name = self.name,
		type = GUILD_CHANNEL_TYPE_MAP[self.type],
		position = self.position,
		permission_overwrites = #self.permissionOverwrites > 0 and self.permissionOverwrites or nil,

		flags = self.flags,
		icon = self.icon,

		topic = self.topic,
		bitrate = self.bitrate,
		user_limit = self.userLimit,
		rate_limit_per_user = self.rateLimitPerUser,
		parent_id = self.parentId,
		nsfw = self.nsfw,
		rtc_region = self.rtcRegion,
		video_quality_mode = GUILD_VIDEO_QUALITY_MODE_MAP[self.videoQualityMode],
		default_auto_archive_duration = self.defaultAutoArchiveDuration,
		default_reaction_emoji = self.defaultReactionEmoji,
		available_tags = self.availableTags,
		default_sort_order = GUILD_SORT_ORDER_MAP[self.defaultSortOrder],
		default_forum_layout = GUILD_FORUM_LAYOUT_MAP[self.defaultForumLayout],
		default_thread_rate_limit_per_user = self.defaultThreadRateLimitPerUser,
	}
end

--[[
	Constructor for the Discord Channel Builder.
]]
function Channel.Interface.new(resource: {
	channelName: string?,
	channelType: apiTypes.ChannelType?,
	channelPosition: number?,
	channelPermissionOverwrites: { apiTypes.OverwriteObject }?,
}?): Channel
	local self = setmetatable(
		{
			permissionOverwrites = {},
		} :: Channel,
		{ __index = Channel.Prototype }
	)

	if resource and resource.channelType then
		self:setType(resource.channelType)
	end

	if resource and resource.channelName then
		self:setName(resource.channelName)
	end

	if resource and resource.channelPosition then
		self:setPosition(resource.channelPosition)
	end

	if resource and resource.channelPermissionOverwrites then
		self:setOverwrites(resource.channelPermissionOverwrites)
	end

	return self
end

export type Channel = typeof(Channel.Prototype) & {
	id: apiTypes.Snowflake?,

	name: string?,
	type: apiTypes.ChannelType,
	permissionOverwrites: { apiTypes.OverwriteObject },
	position: number?,

	-- DM
	icon: string?,
	flags: number?,

	-- TEXT
	topic: string?,
	rateLimitPerUser: number?,
	parentId: apiTypes.Snowflake?,
	nsfw: boolean?,
	defaultAutoArchiveDuration: number?,
	defaultThreadRateLimitPerUser: number?,

	-- MEDIA
	defaultReactionEmoji: apiTypes.DefaultReactionObject?,
	availableTags: { apiTypes.ForumTagObject }?,
	defaultSortOrder: apiTypes.ForumSortOrder?,

	-- FORUM
	defaultForumLayout: apiTypes.ForumLayout?,

	-- VOICE
	videoQualityMode: apiTypes.VideoQualityMode?,
	rtcRegion: string?,
	rateLimitPerUser: number?,
	userLimit: number?,
	bitrate: number?,
}

export type JSON = typeof(Channel.Prototype.build(nil :: any))

return Channel.Interface
