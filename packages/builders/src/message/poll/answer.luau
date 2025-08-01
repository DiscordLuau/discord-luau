--[=[
	@class Builders.PollAnswer
	@__index Prototype

	Implementation of discords PollAnswer object as a Luau builder.	

	https://discord.com/developers/docs/resources/poll#poll-answer-object-poll-answer-object-structure
]=]

local mediaBuilder = require("./media")

local PollAnswer = {}

PollAnswer.Prototype = {}
PollAnswer.Interface = {}

--[=[
	@within Builders.PollAnswer

	Sets the ID for the poll answer.
]=]
function PollAnswer.Prototype.setId(self: PollAnswer, id: number): PollAnswer
	self.answerId = id

	return self
end

--[=[
	@within Builders.PollAnswer

	Sets the media for the poll answer.
]=]
function PollAnswer.Prototype.setMedia(self: PollAnswer, media: mediaBuilder.JSON): PollAnswer
	self.pollMedia = media

	return self
end

--[=[
	@within Builders.PollAnswer

	Responsible for building the PollAnswer JSON that can be parsed by the Discord API.
]=]
function PollAnswer.Prototype.build(self: PollAnswer): JSON
	assert(self.answerId, "answerId must be set")
	assert(self.pollMedia, "pollMedia must be set")

	return {
		answer_id = self.answerId,
		poll_media = self.pollMedia,
	}
end

--[=[
	@within Builders.PollAnswer

	Responsible for creating a new PollAnswer.

	```luau
	local answer = PollAnswer.new({
		answerId = 1,
		pollMedia = media:build()
	})
	```
]=]
function PollAnswer.Interface.new(resource: {
	answerId: number?,
	pollMedia: mediaBuilder.JSON?,
}?): PollAnswer
	local self = setmetatable(
		{
			--[=[
				@prop answerId number?
				@within Builders.PollAnswer
				The ID of the poll answer.
			]=]
			answerId = nil,

			--[=[
				@prop pollMedia Builders.Media?
				@within Builders.PollAnswer
				The media attached to this poll answer.
			]=]
			pollMedia = nil,
		} :: PollAnswer,
		{
			__index = PollAnswer.Prototype,
		}
	)

	if resource then
		if resource.answerId then
			self:setId(resource.answerId)
		end

		if resource.pollMedia then
			self:setMedia(resource.pollMedia)
		end
	end

	return self
end

export type PollAnswer = typeof(PollAnswer.Prototype) & {
	answerId: number?,
	pollMedia: mediaBuilder.JSON?,
}

export type JSON = typeof(PollAnswer.Prototype.build(nil :: any))

return PollAnswer.Interface
