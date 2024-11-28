--[[
	Implementation of the Discord Activity class in Luau

	https://discord.com/developers/docs/resources/message#message-object-message-activity-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local Activity = {}

Activity.Interface = {}
Activity.Prototype = {}

function Activity.Prototype.sync(self: Activity, activityData: apiTypes.MessageActivityObject)
	self.type = apiTypes.message.MessageAcitvityType[activityData.type]
	self.partyId = activityData.party_id
end

function Activity.Interface.new(activityData: apiTypes.MessageActivityObject): Activity
	local self = setmetatable({} :: Activity, { __index = Activity.Prototype })

	self:sync(activityData)

	return self
end

export type Activity = typeof(Activity.Prototype) & {
	type: apiTypes.MessageAcitvityType,
	partyId: string?,
}

return Activity.Interface
