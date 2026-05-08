--[=[
	@class Builders.Message.Poll
	@__index Prototype

	Implementation of discords Poll object as a Luau builder.	

	https://discord.com/developers/docs/resources/poll#poll-object
]=]

--[=[
	@prop question Builders.Media
	@within Builders.Message.Poll
	The question to be displayed in the poll.
]=]

--[=[
	@prop answers {Builders.Answer}
	@within Builders.Message.Poll
	The array of possible answers for the poll.
]=]

--[=[
	@prop duration number
	@within Builders.Message.Poll
	Duration in hours for the poll. Discord converts this to an expiry timestamp internally.
]=]

--[=[
	@prop allowMultiselect boolean
	@within Builders.Message.Poll
	Whether users can select multiple answers.
]=]

--[=[
	@prop layoutType api_types.PollLayoutType
	@within Builders.Message.Poll
	The layout type of the poll display.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local mediaBuilder = require("./media")
local answerBuilder = require("./answer")

local Poll = {}

Poll.Prototype = {}
Poll.Interface = {}

--[=[
	@within Builders.Message.Poll

	Adds an answer to the poll.
]=]
function Poll.Prototype.addAnswer(self: Poll, answer: answerBuilder.JSON): Poll
	assert(#self.answers < 10, "polls cannot have more than 10 answers")
	table.insert(self.answers, answer)

	return self
end

--[=[
	@within Builders.Message.Poll

	Sets the question for the poll.
]=]
function Poll.Prototype.setQuestion(self: Poll, question: mediaBuilder.JSON): Poll
	self.question = question

	return self
end

--[=[
	@within Builders.Message.Poll

	Sets the duration of the poll in hours. Must be a positive integer.
	Discord uses this to calculate the expiry timestamp internally.
]=]
function Poll.Prototype.setDuration(self: Poll, hours: number): Poll
	assert(hours > 0, "Poll duration must be a positive number of hours")

	self.duration = hours

	return self
end

--[=[
	@within Builders.Message.Poll

	Sets whether the poll allows multiple selections.
]=]
function Poll.Prototype.setMultiselect(self: Poll, multiselect: boolean): Poll
	self.allowMultiselect = multiselect

	return self
end

--[=[
	@within Builders.Message.Poll

	Sets the layout type for the poll.
]=]
function Poll.Prototype.setLayoutType(self: Poll, layoutType: apiTypes.PollLayoutType): Poll
	self.layoutType = layoutType

	return self
end

--[=[
	@within Builders.Message.Poll

	Builds and returns the Poll JSON that can be parsed by the Discord API.
]=]
function Poll.Prototype.build(self: Poll): JSON
	assert(self.question, "Poll question is required")
	assert(self.answers and #self.answers >= 1, "polls must have at least 1 answer")
	assert(#self.answers <= 10, "polls cannot have more than 10 answers")
	assert(self.allowMultiselect ~= nil, "allowMultiselect must be set before building a poll")
	assert(self.layoutType, "Poll layout type is required")

	return {
		question = self.question,
		answers = #self.answers > 0 and self.answers or nil,
		duration = self.duration,
		allow_multiselect = self.allowMultiselect,
		layout_type = apiTypes.message.PollLayoutType[self.layoutType],
		results = nil,
	}
end

--[=[
	@within Builders.Message.Poll

	Responsible for creating a new Poll.
]=]
function Poll.Interface.new(resource: {
	question: mediaBuilder.JSON?,
	answers: { answerBuilder.JSON }?,
	duration: number?,
	allowMultiselect: boolean?,
	layoutType: apiTypes.PollLayoutType?,
}?): Poll
	local self = setmetatable(
		{
			answers = {},
		} :: Poll,
		{
			__index = Poll.Prototype,
		}
	)

	if resource then
		if resource.question then
			self:setQuestion(resource.question)
		end

		if resource.duration then
			self:setDuration(resource.duration)
		end

		if resource.allowMultiselect ~= nil then
			self:setMultiselect(resource.allowMultiselect)
		end

		if resource.layoutType then
			self:setLayoutType(resource.layoutType)
		end

		if resource.answers then
			for _, answer in resource.answers do
				self:addAnswer(answer)
			end
		end
	end

	return self
end

export type Poll = typeof(Poll.Prototype) & {
	question: mediaBuilder.JSON,
	answers: { answerBuilder.JSON },
	duration: number?,
	allowMultiselect: boolean,
	layoutType: apiTypes.PollLayoutType,
}

export type JSON = typeof(Poll.Prototype.build(nil :: any))

return Poll.Interface
