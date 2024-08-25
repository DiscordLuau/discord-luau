local apiTypes = require("@api-types/apiTypes")

local overwrite = require("@classes/channels/overwrite")

local GuildBehaviour = {}

GuildBehaviour.Interface = {}
GuildBehaviour.Prototype = {}

function GuildBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	local permissionOverwriteArray = {}

	for _, overwriteData in channelData.permission_overwrites do
		table.insert(permissionOverwriteArray, overwrite.new(overwriteData))
	end

	class.permissionOverwrites = permissionOverwriteArray

	class.nsfw = channelData.nsfw
	class.topic = channelData.topic
	class.guildId = channelData.guild_id
	class.position = channelData.position
	class.parentId = channelData.parent_id
	class.permissions = channelData.permissions
	class.defaultThreadRateLimitPerUser = channelData.rate_limit_per_user
	class.defaultAutoArchiveDuration = channelData.default_auto_archive_duration
end

function GuildBehaviour.Interface.inheritMethods(class: any)
	for key, value in GuildBehaviour.Prototype do
		class[key] = value
	end
end

export type GuildBehaviourMethods = typeof(GuildBehaviour.Prototype)
export type GuildBehaviourProperties = {
	permissionOverwrites: { overwrite.Overwrite },
	nsfw: boolean,
	topic: string?,
	guildId: string,
	position: number,
	parentId: string?,
	permissions: number,
	defaultThreadRateLimitPerUser: number,
	defaultAutoArchiveDuration: number,
}

export type GuildBehaviour = GuildBehaviourMethods & GuildBehaviourProperties

return GuildBehaviour.Interface
