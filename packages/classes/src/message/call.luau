--[=[
	@class Classes.Call
	@__index Prototype

	Implementation of the Discord Call class in Luau

	https://discord.com/developers/docs/resources/message#message-call-object
]=]

local stdPolyfills = require("../../lune_packages/std_polyfills")

local apiTypes = require("../../lune_packages/api_types")

local user = require("../user")

local Call = {}

Call.Interface = {}
Call.Prototype = {}

--[=[
	@within Classes.Call
	@private

	Responsible for syncing data to this call object. This is typically called by the API when this object is
	created or updated.
]=]
function Call.Prototype.sync(self: Call, callData: apiTypes.MessageCallObject)
	--[=[
		@prop participants { Classes.User }
		@within Classes.Call
		Array of user objects that participated in the call
	]=]
	local userArray = {}

	for _, userData in callData.participants do
		table.insert(userArray, user.new(userData))
	end

	self.participants = userArray

	--[=[
		@prop endedTimestamp DateTime
		@within Classes.Call
		When the call ended, stored as a DateTime object
	]=]
	self.endedTimestamp = stdPolyfills.datetime.fromIsoDate(callData.ended_timestamp)
end

--[=[
	@within Classes.Call
	@private

	Responsible for constructing this class.
]=]
function Call.Interface.new(callData: apiTypes.MessageCallObject): Call
	local self = setmetatable({} :: Call, { __index = Call.Prototype })

	self:sync(callData)

	return self
end

export type Call = typeof(Call.Prototype) & {
	participants: { user.User },
	endedTimestamp: stdPolyfills.DateTime,
}

return Call.Interface
