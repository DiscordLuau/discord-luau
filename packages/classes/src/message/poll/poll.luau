--[[
	Implementation of the Discord Poll class in Luau

	https://discord.com/developers/docs/resources/poll#poll-object
]]

local datetime = require("@std-polyfills/datetime")

local apiTypes = require("@api-types/apiTypes")
local pollTypes = require("@api-types/poll")

local answer = require("@classes/message/poll/answer")
local mediaObject = require("@classes/message/poll/mediaObject")
local results = require("@classes/message/poll/results")

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
	self.expiry = pollData.expiry and datetime.fromIsoDate(pollData.expiry)
	self.allowMultiselect = pollData.allow_multiselect
	self.layoutType = (pollData.layout_type == 1 and "Default") :: pollTypes.PollLayoutType
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
	expiry: datetime.DateTime?,
	allowMultiselect: boolean,
	layoutType: pollTypes.PollLayoutType,
	results: results.Results?,
}

return Poll.Interface
