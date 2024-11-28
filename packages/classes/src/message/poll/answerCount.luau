--[[
	Implementation of the Discord AnswerCount class in Luau

	packages/classes/src/message/poll/results.luau
]]

local apiTypes = require("../../../lune_packages/api_types")

local AnswerCount = {}

AnswerCount.Interface = {}
AnswerCount.Prototype = {}

function AnswerCount.Prototype.sync(self: AnswerCount, answerCountData: apiTypes.PollAnswerCountObject)
	self.id = answerCountData.id
	self.count = answerCountData.count
	self.meVoted = answerCountData.me_voted
end

function AnswerCount.Interface.new(answerCountData: apiTypes.PollAnswerCountObject): AnswerCount
	local self = setmetatable({} :: AnswerCount, { __index = AnswerCount.Prototype })

	self:sync(answerCountData)

	return self
end

export type AnswerCount = typeof(AnswerCount.Prototype) & {
	id: number,
	count: number,
	meVoted: boolean,
}

return AnswerCount.Interface
