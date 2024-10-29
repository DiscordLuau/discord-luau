local apiTypes = require("@api-types/apiTypes")
local channelTypes = require("@api-types/channel")

local dmChannel = require("@classes/channels/types/dm")
local groupDmChannel = require("@classes/channels/types/groupDm")
local guildAnnouncement = require("@classes/channels/types/guildAnnouncement")
local guildCategory = require("@classes/channels/types/guildCategory")
local guildDirectory = require("@classes/channels/types/guildDirectory")
local guildStageVoice = require("@classes/channels/types/guildStageVoice")
local guildText = require("@classes/channels/types/guildText")
local guildVoice = require("@classes/channels/types/guildVoice")

local announcementThread = require("@classes/channels/threads/announcement")
local forumThread = require("@classes/channels/threads/forum")
local mediaThread = require("@classes/channels/threads/media")
local privateThread = require("@classes/channels/threads/private")
local publicThread = require("@classes/channels/threads/public")

return function<T>(channelData: apiTypes.ChannelObject): T?
	local object: any

	if channelData.type == channelTypes.ChannelTypes.GuildText then
		object = guildText.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.DM then
		object = dmChannel.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildVoice then
		object = guildVoice.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GroupDM then
		object = groupDmChannel.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildCategory then
		object = guildCategory.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildAnnouncement then
		object = guildAnnouncement.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.AnnouncementThread then
		object = announcementThread.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.PublicThread then
		object = publicThread.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.PrivateThread then
		object = privateThread.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildStageVoice then
		object = guildStageVoice.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildDirectory then
		object = guildDirectory.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildForum then
		object = forumThread.new(channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildMedia then
		object = mediaThread.new(channelData)
	end

	return object :: T
end
