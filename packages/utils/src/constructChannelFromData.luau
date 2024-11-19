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

-- selene: allow(unused_variable)
local state = require("@classes/state")

return function<T>(state: state.State, channelData: apiTypes.ChannelObject): T?
	local object: any

	if channelData.type == channelTypes.ChannelTypes.GuildText then
		object = guildText.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.DM then
		object = dmChannel.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildVoice then
		object = guildVoice.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GroupDM then
		object = groupDmChannel.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildCategory then
		object = guildCategory.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildAnnouncement then
		object = guildAnnouncement.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.AnnouncementThread then
		object = announcementThread.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.PublicThread then
		object = publicThread.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.PrivateThread then
		object = privateThread.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildStageVoice then
		object = guildStageVoice.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildDirectory then
		object = guildDirectory.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildForum then
		object = forumThread.new(state, channelData)
	elseif channelData.type == channelTypes.ChannelTypes.GuildMedia then
		object = mediaThread.new(state, channelData)
	end

	return object :: T
end
