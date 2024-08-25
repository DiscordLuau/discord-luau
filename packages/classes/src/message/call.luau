--[[
	Implementation of the Discord Call class in Luau

	https://discord.com/developers/docs/resources/message#message-call-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")

local user = require("@classes/user")

local Call = {}

Call.Interface = {}
Call.Prototype = {}

function Call.Prototype.sync(self: Call, callData: apiTypes.MessageCallObject)
	local userArray = {}

	for _, userData in callData.participants do
		table.insert(userArray, user.new(userData))
	end

	self.participants = userArray
	self.endedTimestamp = datetime.fromIsoDate(callData.ended_timestamp)
end

function Call.Interface.new(callData: apiTypes.MessageCallObject): Call
	local self = setmetatable({} :: Call, { __index = Call.Prototype })

	self:sync(callData)

	return self
end

export type Call = typeof(Call.Prototype) & {
	participants: { user.User },
	endedTimestamp: datetime.DateTime,
}

return Call.Interface
