--[[
	Implementation of the Discord Answer class in Luau

	https://discord.com/developers/docs/resources/poll#poll-answer-object-poll-answer-object-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local mediaObject = require("./mediaObject")

local Answer = {}

Answer.Interface = {}
Answer.Prototype = {}

function Answer.Prototype.sync(self: Answer, answerData: apiTypes.PollAnswerObject)
	self.answerId = answerData.answer_id
	self.pollMedia = mediaObject.new(answerData.poll_media)
end

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
