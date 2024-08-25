--[[
	Group DM Behaviour, responsible for implementing the various properties, and methods for a group DM.
]]

local apiTypes = require("@api-types/apiTypes")

local user = require("@classes/user")

local DMBehaviour = {}

DMBehaviour.Interface = {}
DMBehaviour.Prototype = {}

function DMBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	local recipientArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, recipient in next, channelData.recipients or {} do
		table.insert(recipientArray, user.new(recipient))
	end

	class.recipients = recipientArray
	class.icon = channelData.icon
	class.ownerId = channelData.owner_id
	class.applicationId = channelData.application_id
	class.managed = channelData.managed
end

function DMBehaviour.Interface.inheritMethods(class: any)
	for key, value in DMBehaviour.Prototype do
		class[key] = value
	end
end

export type DMBehaviourMethods = typeof(DMBehaviour.Prototype)
export type DMBehaviourProperties = {
	recipients: { user.User },
	icon: string?,
	ownerId: string?,
	applicationId: string?,
	managed: boolean,
}

export type DMBehaviour = DMBehaviourMethods & DMBehaviourProperties

return DMBehaviour.Interface
