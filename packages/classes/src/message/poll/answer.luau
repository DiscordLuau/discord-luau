--[=[
	@class Classes.Message.PollAnswer
	@__index Prototype

	Implementation of the Discord Answer class in Luau

	https://discord.com/developers/docs/resources/poll#poll-answer-object-poll-answer-object-structure
]=]

--[=[
	@prop answerId number
	@within Classes.Message.PollAnswer
	The unique identifier for this poll answer option
]=]

--[=[
	@prop pollMedia Classes.Message.PollMediaObject
	@within Classes.Message.PollAnswer
	The media content representing this answer option
]=]

local apiTypes = require("../../../luau_packages/api_types")

local mediaObject = require("./mediaObject")

local Answer = {}

Answer.Interface = {}
Answer.Prototype = {}

--[=[
	@within Classes.Message.PollAnswer
	@private

	Responsible for syncing data to this answer object. This is typically called by the API when this object is
	created or updated.
]=]
function Answer.Prototype.sync(self: Answer, answerData: apiTypes.PollAnswerObject)
	self.answerId = answerData.answer_id

	self.pollMedia = mediaObject.new(answerData.poll_media)
end

--[=[
	@within Classes.Message.PollAnswer
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
