local Enumerate = require("@util/enumerate")
local construct = require("@util/construct")

local ResolvableType = require("@enums/resolvableType")
local Resolvable = require("@network/resolvable")

local PermissionsBuilder = require("@builders/permissions")

--[=[
	@class Builders.ChannelBuilder
]=]
local ChannelBuilder = {}

ChannelBuilder.Interface = {}
ChannelBuilder.Prototype = {}

ChannelBuilder.Prototype.type = "ChannelBuilder"

--[=[
	@prop Type table
	@within Builders.ChannelBuilder

	An enumeration of activity types.

	- Game: 0
	- Streaming: 1
	- Listening: 2
	- Watching: 3
	- Competing: 5
]=]
ChannelBuilder.Interface.Type = Enumerate.new({
	GuildTextChannel = 0,
	GuildVoiceChannel = 2,
	GuildCategoryChannel = 4,
	GuildAnnouncementChannel = 5,
	GuildForumChannel = 15,
	GuildMediaChannel = 16,
})

--[=[
	@prop VideoQualityMode table
	@within Builders.ChannelBuilder

	An enumeration of activity types.

	- QualityAuto: 1
	- Quality720p: 2
]=]
ChannelBuilder.Interface.VideoQualityMode = Enumerate.new({
	QualityAuto = 1,
	Quality720p = 2,
})

--[=[
	@prop SortOrder table
	@within Builders.ChannelBuilder

	An enumeration of activity types.

	- LatestActivity: 0
	- CreationDate: 1
]=]
ChannelBuilder.Interface.SortOrder = Enumerate.new({
	LatestActivity = 0,
	CreationDate = 1,
})

--[=[
	@prop ForumLayout table
	@within Builders.ChannelBuilder

	An enumeration of activity types.

	- NotSet: 0
	- ListView: 1
	- GalleryView: 2
]=]
ChannelBuilder.Interface.ForumLayout = Enumerate.new({
	NotSet = 0,
	ListView = 1,
	GalleryView = 2,
})

--[=[
	Sets the type of the current discord channel.
	
	@method setType
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setType(self: ChannelBuilder, type: number)
	ChannelBuilder.Interface.Type:Assert(type)

	self.channelType = type :: any

	return self
end

--[=[
	Sets the bitrate of the current discord voice channel.
	
	@method setBitrate
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setBitrate(self: ChannelBuilder, bitrate: number)
	self.bitrate = bitrate

	return self
end

--[=[
	Sets the region of the current discord voice channel.
	
	@method setRegion
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setRegion(self: ChannelBuilder, regionId: number)
	self.region = regionId

	return self
end

--[=[
	Sets the Video Quality Mode of a discord voice channel
	
	@method setVideoQualityMode
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setVideoQualityMode(self: ChannelBuilder, videoQualityMode: number)
	ChannelBuilder.Interface.VideoQualityMode:Assert(videoQualityMode)

	self.videoQualityMode = videoQualityMode

	return self
end

--[=[
	Sets an overwrite for a Member, allowing you to define allowed permissions, alongside dissallowed permissions.
	
	@method addMemberOverwrite
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.addMemberOverwrite(
	self: ChannelBuilder,
	roleId: string,
	allowedPermissions: PermissionsBuilder.PermissionsBuilder,
	deniedPermissions: PermissionsBuilder.PermissionsBuilder
)
	table.insert(self.overwrites, {
		id = roleId,
		type = 1,
		allow = allowedPermissions,
		deny = deniedPermissions,
	})

	return self
end

--[=[
	Sets an overwrite for a Role, allowing you to define allowed permissions, alongside dissallowed permissions.
	
	@method addRoleOverwrite
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.addRoleOverwrite(
	self: ChannelBuilder,
	roleId: string,
	allowedPermissions: PermissionsBuilder.PermissionsBuilder,
	deniedPermissions: PermissionsBuilder.PermissionsBuilder
)
	table.insert(self.overwrites, {
		id = roleId,
		type = 0,
		allow = allowedPermissions,
		deny = deniedPermissions,
	})

	return self
end

--[=[
	Sets the default reaction for Forum and Media channels.
	
	@method setDefaultReaction
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setDefaultReaction(self: ChannelBuilder, emojiId: string, emojiName: string)
	self.defaultReaction = {
		emojiId = emojiId,
		emojiName = emojiName,
	}

	return self
end

--[=[
	Sets the default sort order for Forum and Media channels.
	
	@method setDefaultSortOrder
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setDefaultSortOrder(self: ChannelBuilder, sortOrder: number)
	ChannelBuilder.Interface.SortOrder:Assert(sortOrder)

	self.sortOrder = sortOrder

	return self
end

--[=[
	Sets the Default layout for Forum channels.
	
	@method setDefaultForumLayout
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setDefaultForumLayout(self: ChannelBuilder, layoutOrder: number)
	ChannelBuilder.Interface.ForumLayout:Assert(layoutOrder)

	self.forumLayout = layoutOrder

	return self
end

--[=[
	Sets the name of the Discord Channel
	
	@method setPosition
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setName(self: ChannelBuilder, name: string)
	self.name = name

	return self
end

--[=[
	Sets the position of a Discord Channel, the position determines the position the channel appears in the channel hierarchy.
	
	@method setPosition
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setPosition(self: ChannelBuilder, position: number)
	self.position = position

	return self
end

--[=[
	Sets the topic of a Discord Channel.
	
	@method setTopic
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setTopic(self: ChannelBuilder, topic: string)
	self.topic = topic

	return self
end

--[=[
	Locks the channel to be NSFW only.
	
	@method setNSFW
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setNSFW(self: ChannelBuilder, nsfw: boolean)
	self.isNsfw = nsfw

	return self
end

--[=[
	Sets the rate limit per user for a discord channel.
	
	@method setRateLimitPerUser
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setRateLimitPerUser(self: ChannelBuilder, limit: number)
	self.rateLimitPerUser = limit

	return self
end

--[=[
	Sets the parent category of a discord channel.
	
	@method setParentCategoryId
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setParentCategoryId(self: ChannelBuilder, parentId: string)
	self.parentCategoryId = parentId

	return self
end

--[=[
	Sets the default archive duration for a discord channel.
	
	@method setDefaultAutoArchiveDuration
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setDefaultAutoArchiveDuration(self: ChannelBuilder, duration: number)
	self.defaultAutoArchiveDuration = duration

	return self
end

--[=[
	Sets the default thread limit for each user in a discord channel.
	
	@method setDefaultThreadRateLimitPerUser
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder
]=]
function ChannelBuilder.Prototype.setDefaultThreadRateLimitPerUser(self: ChannelBuilder, limit: number)
	self.threadRateLimitPerUser = limit

	return self
end

--[=[
	Converts the activity to a JSON object that can be sent to the Discord API.
	
	@method toPayloadObject
	@within Builders.ChannelBuilder
	@return Network.Resolvable
]=]
function ChannelBuilder.Prototype.toPayloadObject(self: ChannelBuilder)
	local overwrites = {}

	for _, object in self.overwrites do
		table.insert(overwrites, {
			id = object.id,
			type = object.type,
			allow = object.allow:getValue(),
			deny = object.deny:getValue(),
		})
	end

	return Resolvable.new(ResolvableType.JSON, {
		name = self.name,
		bitrate = self.bitrate,
		type = self.channelType,
		rtc_region = self.region,
		video_quality_mode = self.videoQualityMode,
		sort_order = self.sortOrder,
		forum_layout = self.forumLayout,
		position = self.position,
		topic = self.topic,
		is_nsfw = self.isNsfw,
		rate_limit_per_user = self.rateLimitPerUser,
		parent_id = self.parentCategoryId,
		default_auto_archive_duration = self.defaultAutoArchiveDuration,
		thread_rate_limit_per_user = self.threadRateLimitPerUser,

		permission_overwrites = #overwrites > 0 and overwrites or nil,

		default_reaction_emoji = self.defaultReaction and {
			emoji_id = self.defaultReaction.emojiId,
			emoji_name = self.defaultReaction.emojiName,
		} or nil,
	})
end

--[=[
	Creates a new instance of ChannelBuilder.
	
	@function new
	@within Builders.ChannelBuilder
	@return Builders.ChannelBuilder -- A new instance of ChannelBuilder.
]=]
function ChannelBuilder.Interface.new()
	return (construct({
		overwrites = {},
	}, ChannelBuilder.Prototype) :: unknown) :: ChannelBuilder
end

export type ChannelBuilder = typeof(ChannelBuilder.Prototype) & {
	name: string?,
	bitrate: number?,
	channelType: number?,
	region: number?,
	-- flags: number?, -- to-do: add channel flag support!
	-- tags: { ? } -- to-do: add channel tags support!
	videoQualityMode: number?,
	sortOrder: number?,
	forumLayout: number?,
	position: number?,
	topic: string?,
	isNsfw: boolean?,
	rateLimitPerUser: number?,
	parentCategoryId: string?,
	defaultAutoArchiveDuration: number?,
	threadRateLimitPerUser: number?,

	defaultReaction: {
		emojiId: string,
		emojiName: string,
	}?,

	overwrites: {
		{
			id: string,
			type: number,
			allow: PermissionsBuilder.PermissionsBuilder,
			deny: PermissionsBuilder.PermissionsBuilder,
		}
	},
}

return ChannelBuilder.Interface
