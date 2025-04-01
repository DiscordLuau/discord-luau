--[=[
	@class Classes.Results
	@__index Prototype

	Implementation of the Discord Results class in Luau

	https://discord.com/developers/docs/resources/poll#poll-results-object-poll-results-object-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local answerCount = require("./answerCount")

local Results = {}

Results.Interface = {}
Results.Prototype = {}

--[=[
	@within Classes.Results
	@private

	Responsible for syncing data to this results object. This is typically called by the API when this object is
	created or updated.
]=]
function Results.Prototype.sync(self: Results, resultsData: apiTypes.PollResultObject)
	local countArray = {}

	for _, answerCountData in resultsData.answer_counts do
		table.insert(countArray, answerCount.new(answerCountData))
	end

	--[=[
		@prop isFinalized boolean
		@within Classes.Results
		Whether the poll results are finalized and can no longer be updated
	]=]
	self.isFinalized = resultsData.is_finalized

	--[=[
		@prop answerCounts { Classes.AnswerCount }
		@within Classes.Results
		Array of answer counts for each poll option
	]=]
	self.answerCounts = countArray
end

--[=[
	@within Classes.Results
	@private

	Responsible for constructing this class.
]=]
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
