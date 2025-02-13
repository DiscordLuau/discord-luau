--[[
	Implementation of the Discord Call class in Luau

	https://discord.com/developers/docs/resources/message#message-call-object
]]

local stdPolyfills = require("../../lune_packages/std_polyfills")

local apiTypes = require("../../lune_packages/api_types")

local user = require("../user")

local Call = {}

Call.Interface = {}
Call.Prototype = {}

function Call.Prototype.sync(self: Call, callData: apiTypes.MessageCallObject)
	local userArray = {}

	for _, userData in callData.participants do
		table.insert(userArray, user.new(userData))
	end

	self.participants = userArray
	self.endedTimestamp = stdPolyfills.datetime.fromIsoDate(callData.ended_timestamp)
end

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
