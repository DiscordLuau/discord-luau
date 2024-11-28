--[[
	Implementation of the Discord Poll class in Luau

	https://discord.com/developers/docs/resources/poll#poll-object
]]

local stdPolyfills = require("../../../lune_packages/std_polyfills")

local apiTypes = require("../../../lune_packages/api_types")

local answer = require("./answer")
local mediaObject = require("./mediaObject")
local results = require("./results")

local Poll = {}

Poll.Interface = {}
Poll.Prototype = {}

function Poll.Prototype.sync(self: Poll, pollData: apiTypes.PollObject)
	local answerArray = {}

	for _, answerData in pollData.answers do
		table.insert(answerArray, answer.new(answerData))
	end

	self.answers = answerArray

	self.question = mediaObject.new(pollData.question)
	self.expiry = pollData.expiry and stdPolyfills.datetime.fromIsoDate(pollData.expiry)
	self.allowMultiselect = pollData.allow_multiselect
	self.layoutType = (pollData.layout_type == 1 and "Default") :: apiTypes.PollLayoutType
	self.results = pollData.results and results.new(pollData.results)
end

function Poll.Interface.new(pollData: apiTypes.PollObject): Poll
	local self = setmetatable({} :: Poll, { __index = Poll.Prototype })

	self:sync(pollData)

	return self
end

export type Poll = typeof(Poll.Prototype) & {
	question: mediaObject.MediaObject,
	answers: { answer.Answer },
	expiry: stdPolyfills.DateTime?,
	allowMultiselect: boolean,
	layoutType: apiTypes.PollLayoutType,
	results: results.Results?,
}

return Poll.Interface
