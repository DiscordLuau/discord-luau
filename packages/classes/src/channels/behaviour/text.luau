local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")

local TextBehaviour = {}

TextBehaviour.Interface = {}
TextBehaviour.Prototype = {}

function TextBehaviour.Interface.inheritProperties(class: any, channelData: apiTypes.ChannelObject)
	class.lastMessageId = channelData.last_message_id
	class.lastPinTimestamp = channelData.last_pin_timestamp and datetime.fromIsoDate(channelData.last_pin_timestamp)
	class.rateLimitPerUser = channelData.rate_limit_per_user
end

function TextBehaviour.Interface.inheritMethods(class: any)
	for key, value in TextBehaviour.Prototype do
		class[key] = value
	end
end

export type TextBehaviourMethods = typeof(TextBehaviour.Prototype)
export type TextBehaviourProperties = {
	lastMessageId: string?,
	lastPinTimestamp: datetime.DateTime?,
	rateLimitPerUser: number,
}

export type TextBehaviour = TextBehaviourMethods & TextBehaviourProperties

return TextBehaviour.Interface
