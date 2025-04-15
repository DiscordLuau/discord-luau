--[=[
	@class Builders.Poll
	@__index Prototype

	Implementation of discords Poll object as a Luau builder.	

	https://discord.com/developers/docs/resources/poll#poll-object
]=]

local stdPolyfills = require("../../../lune_packages/std_polyfills")

local apiTypes = require("../../../lune_packages/api_types")

local mediaBuilder = require("./media")
local answerBuilder = require("./answer")

local Poll = {}

Poll.Prototype = {}
Poll.Interface = {}

--[=[
	@within Builders.Poll

	Adds an answer to the poll.
]=]
function Poll.Prototype.addAnswer(self: Poll, answer: answerBuilder.JSON): Poll
	table.insert(self.answers, answer)

	return self
end

--[=[
	@within Builders.Poll

	Sets the question for the poll.
]=]
function Poll.Prototype.setQuestion(self: Poll, question: mediaBuilder.JSON): Poll
	self.question = question

	return self
end

--[=[
	@within Builders.Poll

	Sets the expiry time for the poll.
]=]
function Poll.Prototype.setExpiry(self: Poll, expiry: string | number | stdPolyfills.DateTime): Poll
	if typeof(expiry) == "DateTime" then
		local object = expiry :: stdPolyfills.DateTime

		self.expiry = tostring(object.unixTimestampMillis)
	else
		self.expiry = tostring(expiry)
	end

	return self
end

--[=[
	@within Builders.Poll

	Sets whether the poll allows multiple selections.
]=]
function Poll.Prototype.setMultiselect(self: Poll, multiselect: boolean): Poll
	self.allowMultiselect = multiselect

	return self
end

--[=[
	@within Builders.Poll

	Sets the layout type for the poll.
]=]
function Poll.Prototype.setLayoutType(self: Poll, layoutType: apiTypes.PollLayoutType): Poll
	self.layoutType = layoutType

	return self
end

--[=[
	@within Builders.Poll

	Builds and returns the Poll JSON that can be parsed by the Discord API.
]=]
function Poll.Prototype.build(self: Poll): JSON
	assert(self.question, "Poll question is required")
	assert(self.answers, "Poll answers are required")
	assert(self.allowMultiselect, "Poll multiselect is required")
	assert(self.layoutType, "Poll layout type is required")

	return {
		question = self.question,
		answers = self.answers,
		expiry = self.expiry,
		allow_multiselect = self.allowMultiselect,
		layout_type = apiTypes.channel.PollLayoutType[self.layoutType],
		results = nil,
	}
end

--[=[
	@within Builders.Poll

	Responsible for creating a new Poll.
]=]
function Poll.Interface.new(resource: {
	question: mediaBuilder.JSON?,
	answers: { answerBuilder.JSON }?,
	expiry: number?,
	allowMultiselect: boolean?,
	layoutType: apiTypes.PollLayoutType?,
}?): Poll
	local self = setmetatable(
		{
			--[=[
				@prop question Builders.Media
				@within Builders.Poll
				The question to be displayed in the poll.
			]=]
			--[=[
				@prop answers {Builders.Answer}
				@within Builders.Poll
				The array of possible answers for the poll.
			]=]
			answers = {},
			--[=[
				@prop expiry string
				@within Builders.Poll
				The timestamp when the poll will expire.
			]=]
			--[=[
				@prop allowMultiselect boolean
				@within Builders.Poll
				Whether users can select multiple answers.
			]=]
			--[=[
				@prop layoutType api_types.PollLayoutType
				@within Builders.Poll
				The layout type of the poll display.
			]=]
		} :: Poll,
		{
			__index = Poll.Prototype,
		}
	)

	if resource then
		if resource.question then
			self:setQuestion(resource.question)
		end

		if resource.expiry then
			self:setExpiry(resource.expiry)
		end

		if resource.allowMultiselect then
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
	expiry: string,
	allowMultiselect: boolean,
	layoutType: apiTypes.PollLayoutType,
}

export type JSON = typeof(Poll.Prototype.build(nil :: any))

return Poll.Interface
