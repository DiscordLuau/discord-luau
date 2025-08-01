--[=[
	@class Classes.AnswerCount
	@__index Prototype

	Implementation of the Discord AnswerCount class in Luau

	packages/classes/src/message/poll/results.luau
]=]

local apiTypes = require("../../../lune_packages/api_types")

local AnswerCount = {}

AnswerCount.Interface = {}
AnswerCount.Prototype = {}

--[=[
	@within Classes.AnswerCount
	@private

	Responsible for syncing data to this answer count object. This is typically called by the API when this object is
	created or updated.
]=]
function AnswerCount.Prototype.sync(self: AnswerCount, answerCountData: apiTypes.PollAnswerCountObject)
	--[=[
		@prop id number
		@within Classes.AnswerCount
		The ID of the answer being counted
	]=]
	self.id = answerCountData.id

	--[=[
		@prop count number
		@within Classes.AnswerCount
		The number of votes for this answer
	]=]
	self.count = answerCountData.count

	--[=[
		@prop meVoted boolean
		@within Classes.AnswerCount
		Whether the current user has voted for this answer
	]=]
	self.meVoted = answerCountData.me_voted
end

--[=[
	@within Classes.AnswerCount
	@private

	Responsible for constructing this class.
]=]
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
