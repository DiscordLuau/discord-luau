--[=[
	@class Classes.Message.Call
	@__index Prototype

	Implementation of the Discord Call class in Luau

	https://discord.com/developers/docs/resources/message#message-call-object
]=]

--[=[
	@prop participants { Snowflake }
	@within Classes.Message.Call
	Array of user IDs that participated in the call
]=]

--[=[
	@prop endedTimestamp DateTime
	@within Classes.Message.Call
	When the call ended, stored as a DateTime object
]=]

local stdPolyfills = require("../../luau_packages/std_polyfills")

local apiTypes = require("../../luau_packages/api_types")

local Call = {}

Call.Interface = {}
Call.Prototype = {}

--[=[
	@within Classes.Message.Call

	Responsible for syncing data to this call object. This is typically called by the API when this object is
	created or updated.
]=]
function Call.Prototype.sync(self: Call, callData: apiTypes.MessageCallObject)
	self.participants = callData.participants

	self.endedTimestamp = callData.ended_timestamp and stdPolyfills.datetime.fromIsoDate(callData.ended_timestamp)
end

--[=[
	@within Classes.Message.Call

	Responsible for constructing this class.
]=]
function Call.Interface.new(callData: apiTypes.MessageCallObject): Call
	local self = setmetatable({} :: Call, { __index = Call.Prototype })

	self:sync(callData)

	return self
end

export type Call = typeof(Call.Prototype) & {
	participants: { apiTypes.Snowflake },
	endedTimestamp: stdPolyfills.DateTime?,
}

return Call.Interface
