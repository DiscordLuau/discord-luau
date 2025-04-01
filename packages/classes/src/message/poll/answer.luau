--[=[
	@class Classes.Answer
	@__index Prototype

	Implementation of the Discord Answer class in Luau

	https://discord.com/developers/docs/resources/poll#poll-answer-object-poll-answer-object-structure
]=]

local apiTypes = require("../../../lune_packages/api_types")

local mediaObject = require("./mediaObject")

local Answer = {}

Answer.Interface = {}
Answer.Prototype = {}

--[=[
	@within Classes.Answer
	@private

	Responsible for syncing data to this answer object. This is typically called by the API when this object is
	created or updated.
]=]
function Answer.Prototype.sync(self: Answer, answerData: apiTypes.PollAnswerObject)
	--[=[
		@prop answerId number
		@within Classes.Answer
		The unique identifier for this poll answer option
	]=]
	self.answerId = answerData.answer_id

	--[=[
		@prop pollMedia Classes.MediaObject
		@within Classes.Answer
		The media content representing this answer option
	]=]
	self.pollMedia = mediaObject.new(answerData.poll_media)
end

--[=[
	@within Classes.Answer
	@private

	Responsible for constructing this class.
]=]
function Answer.Interface.new(answerData: apiTypes.PollAnswerObject): Answer
	local self = setmetatable({} :: Answer, { __index = Answer.Prototype })

	self:sync(answerData)

	return self
end

export type Answer = typeof(Answer.Prototype) & {
	answerId: number,
	pollMedia: mediaObject.MediaObject,
}

return Answer.Interface
