--[[
	Implementation of the Discord Results class in Luau

	https://discord.com/developers/docs/resources/poll#poll-results-object-poll-results-object-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local answerCount = require("./answerCount")

local Results = {}

Results.Interface = {}
Results.Prototype = {}

function Results.Prototype.sync(self: Results, resultsData: apiTypes.PollResultObject)
	local countArray = {}

	for _, answerCountData in resultsData.answer_counts do
		table.insert(countArray, answerCount.new(answerCountData))
	end

	self.isFinalized = resultsData.is_finalized
	self.answerCounts = countArray
end

function Results.Interface.new(resultsData: apiTypes.PollResultObject): Results
	local self = setmetatable({} :: Results, { __index = Results.Prototype })

	self:sync(resultsData)

	return self
end

export type Results = typeof(Results.Prototype) & {
	isFinalized: boolean,
	answerCounts: { answerCount.AnswerCount },
}

return Results.Interface
