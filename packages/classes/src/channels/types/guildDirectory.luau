--[[
	Implementation of the Discord GuildDirectory class in Luau

	https://discord.com/developers/docs/resources/channel#channel-object
]]

local apiTypes = require("@api-types/apiTypes")

local channelBehaviour = require("@classes/channels/behaviour/channel")
local guildBehaviour = require("@classes/channels/behaviour/guild")

local GuildDirectory = {}

GuildDirectory.Interface = {}
GuildDirectory.Prototype = {}
GuildDirectory.Behaviours = {
	channelBehaviour,
	guildBehaviour,
}

function GuildDirectory.Prototype.sync(self: GuildDirectory, channelData: apiTypes.ChannelObject)
	for _, behaviour in GuildDirectory.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, channelData)
	end
end

function GuildDirectory.Interface.new(channelData: apiTypes.ChannelObject): GuildDirectory
	local self = setmetatable({} :: GuildDirectory, { __index = GuildDirectory.Prototype })

	self:sync(channelData)

	return self
end

export type GuildDirectory =
	typeof(GuildDirectory.Prototype)
	& {}
	& channelBehaviour.ChannelBehaviour
	& guildBehaviour.GuildBehaviour

return GuildDirectory.Interface
