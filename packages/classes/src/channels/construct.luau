-- selene: allow(unused_variable)
local state = require("../../lune_packages/state")
local apiTypes = require("../../lune_packages/api_types")

local dmChannel = require("./types/dm")
local groupDmChannel = require("./types/groupDm")
local guildAnnouncement = require("./types/guildAnnouncement")
local guildCategory = require("./types/guildCategory")
local guildDirectory = require("./types/guildDirectory")
local guildStageVoice = require("./types/guildStageVoice")
local guildText = require("./types/guildText")
local guildVoice = require("./types/guildVoice")

local announcementThread = require("./threads/announcement")
local forumThread = require("./threads/forum")
local mediaThread = require("./threads/media")
local privateThread = require("./threads/private")
local publicThread = require("./threads/public")

return function<T>(state: state.State, channelData: apiTypes.ChannelObject): T?
	local object: any

	if channelData.type == apiTypes.channel.ChannelTypes.GuildText then
		object = guildText.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.DM then
		object = dmChannel.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.GuildVoice then
		object = guildVoice.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.GroupDM then
		object = groupDmChannel.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.GuildCategory then
		object = guildCategory.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.GuildAnnouncement then
		object = guildAnnouncement.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.AnnouncementThread then
		object = announcementThread.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.PublicThread then
		object = publicThread.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.PrivateThread then
		object = privateThread.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.GuildStageVoice then
		object = guildStageVoice.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.GuildDirectory then
		object = guildDirectory.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.GuildForum then
		object = forumThread.new(state, channelData)
	end

	if channelData.type == apiTypes.channel.ChannelTypes.GuildMedia then
		object = mediaThread.new(state, channelData)
	end

	return object :: T
end
