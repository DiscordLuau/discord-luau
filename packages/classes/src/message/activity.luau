--[=[
	@class Classes.Message.Activity
	@__index Prototype

	Implementation of the Discord Activity class in Luau

	https://discord.com/developers/docs/resources/message#message-object-message-activity-structure
]=]

--[=[
	@prop type MessageAcitvityType
	@within Classes.Message.Activity
	Type of message activity, such as JOIN, SPECTATE, LISTEN, or JOIN_REQUEST
]=]

--[=[
	@prop partyId string?
	@within Classes.Message.Activity
	Party ID associated with this activity, used for Rich Presence
]=]

local apiTypes = require("../../luau_packages/api_types")

local Activity = {}

Activity.Interface = {}
Activity.Prototype = {}

--[=[
	@within Classes.Message.Activity
	@private

	Responsible for syncing data to this activity object. This is typically called by the API when this object is
	created or updated.
]=]
function Activity.Prototype.sync(self: Activity, activityData: apiTypes.MessageActivityObject)
	self.type = apiTypes.message.MessageAcitvityType[activityData.type]

	self.partyId = activityData.party_id
end

--[=[
	@within Classes.Message.Activity
	@private

	Responsible for constructing this class.
]=]
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
