--[=[
	@class Classes.MessageActivity
	@__index Prototype

	Implementation of the Discord Activity class in Luau

	https://discord.com/developers/docs/resources/message#message-object-message-activity-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local Activity = {}

Activity.Interface = {}
Activity.Prototype = {}

--[=[
	@within Classes.MessageActivity
	@private

	Responsible for syncing data to this activity object. This is typically called by the API when this object is
	created or updated.
]=]
function Activity.Prototype.sync(self: Activity, activityData: apiTypes.MessageActivityObject)
	--[=[
		@prop type MessageAcitvityType
		@within Classes.MessageActivity
		Type of message activity, such as JOIN, SPECTATE, LISTEN, or JOIN_REQUEST
	]=]
	self.type = apiTypes.message.MessageAcitvityType[activityData.type]

	--[=[
		@prop partyId string?
		@within Classes.MessageActivity
		Party ID associated with this activity, used for Rich Presence
	]=]
	self.partyId = activityData.party_id
end

--[=[
	@within Classes.MessageActivity
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
