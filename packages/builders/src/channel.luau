--[=[
	@class Builders.Channel
	@__index Prototype

	Implementation of a discord Channel as a luau builder.	

	https://discord.com/developers/docs/resources/guild#create-guild-channel
]=]

--[=[
	@prop id string?
	@within Builders.Channel
	The id of the channel.
]=]

--[=[
	@prop name string?
	@within Builders.Channel
	The name of the channel.
]=]

--[=[
	@prop type apiTypes.ChannelType
	@within Builders.Channel
	The type of the channel.
]=]

--[=[
	@prop position number?
	@within Builders.Channel
	Position of the channel in the list.
]=]

--[=[
	@prop icon string?
	@within Builders.Channel
	The base64 icon for the channel (used in DMs).
]=]

--[=[
	@prop flags number?
	@within Builders.Channel
	Bitfield flags for the channel.
]=]

--[=[
	@prop topic string?
	@within Builders.Channel
	The topic of the text channel.
]=]

--[=[
	@prop rateLimitPerUser number?
	@within Builders.Channel
	Slowmode in seconds for users.
	]=]

--[=[
	@prop parentId string?
	@within Builders.Channel
	Parent category ID.
]=]

--[=[
	@prop nsfw boolean?
	@within Builders.Channel
	Whether the channel is marked as NSFW.
]=]

--[=[
	@prop defaultAutoArchiveDuration number?
	@within Builders.Channel
	Default auto archive duration in minutes.
]=]

--[=[
	@prop defaultThreadRateLimitPerUser number?
	@within Builders.Channel
	Slowmode in seconds for thread messages.
]=]

--[=[
	@prop defaultReactionEmoji apiTypes.DefaultReactionObject?
	@within Builders.Channel
	Default reaction emoji object.
]=]

--[=[
	@prop availableTags { apiTypes.ForumTagObject }?
	@within Builders.Channel
	Available forum tags.
]=]

--[=[
	@prop defaultSortOrder apiTypes.ForumSortOrder?
	@within Builders.Channel
	Default sort order for threads.
]=]

--[=[
	@prop defaultForumLayout apiTypes.ForumLayout?
	@within Builders.Channel
	Default forum layout type.
	]=]

--[=[
	@prop videoQualityMode apiTypes.VideoQualityMode?
	@within Builders.Channel
	Voice channel video quality mode.
]=]

--[=[
	@prop rtcRegion string?
	@within Builders.Channel
	Voice region id for the channel.
]=]

--[=[
	@prop userLimit number?
	@within Builders.Channel
	Maximum number of users allowed in the voice channel.
]=]

--[=[
	@prop bitrate number?
	@within Builders.Channel
	Bitrate of the voice channel in bits.
]=]

local apiTypes = require("../lune_packages/api_types")
local util = require("../lune_packages/util")

local Channel = {}

Channel.Prototype = {}
Channel.Interface = {}

--[=[
	@within Builders.Channel

	Set the name of this Channel
]=]
function Channel.Prototype.setName(self: Channel, tagName: string): Channel
	assert(#tagName <= 100, `Channel name must be less than 100 characters.`)
	assert(#tagName > 1, `Channel name must be more than 1 characters.`)

	assert(util.validateKebabCase(tagName), `Channel name must be kebab-case.`)

	self.name = tagName

	return self
end

--[=[
	@within Builders.Channel

	Set the Type of channel this is.
]=]
function Channel.Prototype.setType(self: Channel, channelType: apiTypes.ChannelType): Channel
	self.type = channelType

	return self
end

--[=[
	@within Builders.Channel

	Sets the position of the channel in the discord channels list. Channels with the same position are sorted by id.
]=]
function Channel.Prototype.setPosition(self: Channel, channelPosition: number): Channel
	self.position = channelPosition

	return self
end

--[=[
	@within Builders.Channel

	Adds an overwrite object to the channel's permission overwrites. Channel overwrites are responsible for handling
	user/role permission on a specific channel.
]=]
function Channel.Prototype.setOverwrites(self: Channel, overwriteObjects: { apiTypes.OverwriteObject }): Channel
	self.permissionOverwrites = overwriteObjects

	return self
end

--[=[
	@within Builders.Channel

	Sets the channels topic, topics appear at the top of the discord app and help to inform players about the
	channel's purpose.
]=]
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

--[=[
	@within Builders.Channel

	Sets the bitrate of the voice channel, the bitrate (in bits) of the voice or stage channel.
]=]
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

--[=[
	@within Builders.Channel

	The user limit of the voice channel. The user limit of a voice channel is the maximum number of users allowed in
	the channel at one time.
]=]
function Channel.Prototype.setUserLimit(self: Channel, userLimit: number?): Channel
	assert(
		self.type == "GuildVoice" or self.type == "GuildStageVoice",
		`Channel user limit is only supported for guild voice and stage voice channels.`
	)

	self.userLimit = userLimit

	return self
end

--[=[
	@within Builders.Channel

	Amount of seconds a user has to wait before sending another message. Bots and users with certain permissions are
	unaffected.
]=]
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

--[=[
	@within Builders.Channel

	Set the parent of the channel. Channel parents are categories and can help organize a discord guild.
]=]
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

--[=[
	@within Builders.Channel

	Set whether this channel is NSFW or not.
]=]
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

--[=[
	@within Builders.Channel

	Set the voice region (requires querying voice region ids). Voice regions are regions that Discord uses to host
	voice channels.
]=]
function Channel.Prototype.setVoiceRegion(self: Channel, voiceRegionId: string): Channel
	assert(
		self.type == "GuildVoice" or self.type == "GuildStageVoice",
		`Channel voice region is only supported for voice and stage voice.`
	)

	self.rtcRegion = voiceRegionId

	return self
end

--[=[
	@within Builders.Channel

	Sets the video quality mode of the voice channel.
]=]
function Channel.Prototype.setVideoQualityMode(self: Channel, videoQualityMode: apiTypes.VideoQualityMode): Channel
	assert(
		self.type == "GuildVoice" or self.type == "GuildStageVoice",
		`Channel video quality mode is only supported for voice and stage voice.`
	)

	self.videoQualityMode = videoQualityMode

	return self
end

--[=[
	@within Builders.Channel

	Sets the default auto archive duration for the channel. This is the default duration in minutes for newly created
	threads to automatically archive after recent activity.
]=]
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

--[=[
	@within Builders.Channel

	Sets the default reaction emoji for either a forum or media channel.
]=]
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

--[=[
	@within Builders.Channel

	Specify channel forum tags that are available to the channel.
]=]
function Channel.Prototype.setForumTags(self: Channel, forumTags: { apiTypes.ForumTagObject }): Channel
	assert(
		self.type == "GuildForum" or self.type == "GuildMedia",
		`Channel forum tags are only supported for forum, and media channels.`
	)

	self.availableTags = forumTags

	return self
end

--[=[
	@within Builders.Channel

	Sets the default sort order for the channel.
]=]
function Channel.Prototype.setDefaultSortOrder(self: Channel, sortOrder: apiTypes.ForumSortOrder): Channel
	assert(
		self.type == "GuildForum" or self.type == "GuildMedia",
		`Channel sort order is only supported for forum, and media channels.`
	)

	self.defaultSortOrder = sortOrder

	return self
end

--[=[
	@within Builders.Channel

	Sets the default forum layout for the channel.
]=]
function Channel.Prototype.setDefaultForumLayout(self: Channel, forumLayout: apiTypes.ForumLayout): Channel
	assert(self.type == "GuildForum", `Channel forum layout is only supported for forum channels.`)

	self.defaultForumLayout = forumLayout

	return self
end

--[=[
	@within Builders.Channel

	Sets the default thread rate limit per user for the channel.
]=]
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

--[=[
	@within Builders.Channel

	Sets the channel flags using a bitfield value.
]=]
function Channel.Prototype.setFlags(self: Channel, bitflags: number): Channel
	self.flags = bitflags

	return self
end

--[=[
	@within Builders.Channel

	Sets the channel icon using the provided icon data.
]=]
function Channel.Prototype.setIcon(self: Channel, iconData: string): Channel
	self.icon = iconData

	return self
end

--[=[
	@within Builders.Channel

	Responsible for building the channel object that the Discord API can understand.
]=]
function Channel.Prototype.build(self: Channel): JSON
	return {
		id = self.id,

		name = self.name,
		type = apiTypes.channel.ChannelTypes[self.type],
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
		video_quality_mode = apiTypes.channel.VideoQualityMode[self.videoQualityMode],
		default_auto_archive_duration = self.defaultAutoArchiveDuration,
		default_reaction_emoji = self.defaultReactionEmoji,
		available_tags = self.availableTags,
		default_sort_order = apiTypes.channel.MediaSortOrder[self.defaultSortOrder],
		default_forum_layout = apiTypes.channel.ForumLayout[self.defaultForumLayout],
		default_thread_rate_limit_per_user = self.defaultThreadRateLimitPerUser,
	}
end

--[=[
	@within Builders.Channel

	Constructor for the Discord Channel Builder.
]=]
function Channel.Interface.new(resource: {
	channelName: string?,
	channelType: apiTypes.ChannelType?,
	channelPosition: number?,
	channelPermissionOverwrites: { apiTypes.OverwriteObject }?,
}?): Channel
	local self = setmetatable(
		{
			--[=[
				@prop permissionOverwrites { Builders.OverwriteObject }
				@within Builders.Channel
				List of permission overwrites applied to the channel.
			]=]
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
	icon: string?,
	flags: number?,
	topic: string?,
	rateLimitPerUser: number?,
	parentId: apiTypes.Snowflake?,
	nsfw: boolean?,
	defaultAutoArchiveDuration: number?,
	defaultThreadRateLimitPerUser: number?,
	defaultReactionEmoji: apiTypes.DefaultReactionObject?,
	availableTags: { apiTypes.ForumTagObject }?,
	defaultSortOrder: apiTypes.ForumSortOrder?,
	defaultForumLayout: apiTypes.ForumLayout?,
	videoQualityMode: apiTypes.VideoQualityMode?,
	rtcRegion: string?,
	userLimit: number?,
	bitrate: number?,
}

export type JSON = typeof(Channel.Prototype.build(nil :: any))

return Channel.Interface
