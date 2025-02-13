--[[
	Implementation of discords PollAnswer object as a Luau builder.	

	https://discord.com/developers/docs/resources/poll#poll-answer-object-poll-answer-object-structure
]]

local mediaBuilder = require("./media")

local PollAnswer = {}

PollAnswer.Prototype = {}
PollAnswer.Interface = {}

--[[
	Sets the ID for the poll answer.
]]
function PollAnswer.Prototype.setId(self: PollAnswer, id: number): PollAnswer
	self.answerId = id

	return self
end

--[[
	Sets the media for the poll answer.
]]
function PollAnswer.Prototype.setMedia(self: PollAnswer, media: mediaBuilder.JSON): PollAnswer
	self.pollMedia = media

	return self
end

--[[
	Responsible for building the PollAnswer JSON that can be parsed by the Discord API.
]]
function PollAnswer.Prototype.build(self: PollAnswer): JSON
	assert(self.answerId, "answerId must be set")
	assert(self.pollMedia, "pollMedia must be set")

	return {
		answer_id = self.answerId,
		poll_media = self.pollMedia,
	}
end

--[[
	Responsible for creating a new PollAnswer.

	```lua
	
	```
]]
function PollAnswer.Interface.new(resource: {
	answerId: number?,
	pollMedia: mediaBuilder.JSON?,
}?): PollAnswer
	local self = setmetatable({} :: PollAnswer, {
		__index = PollAnswer.Prototype,
	})

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
