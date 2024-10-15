--[[
	Implementation of discords Poll object as a Luau builder.	

	https://discord.com/developers/docs/resources/poll#poll-object
]]

local datetime = require("@std-polyfills/datetime")

local messageTypes = require("@api-types/message")

local mediaBuilder = require("@builders/message/poll/media")
local answerBuilder = require("@builders/message/poll/answer")

local Poll = {}

Poll.Prototype = {}
Poll.Interface = {}

--[[
	Adds an answer to the poll.
]]
function Poll.Prototype.addAnswer(self: Poll, answer: answerBuilder.JSON): Poll
	table.insert(self.answers, answer)

	return self
end

--[[
	Sets the question for the poll.
]]
function Poll.Prototype.setQuestion(self: Poll, question: mediaBuilder.JSON): Poll
	self.question = question

	return self
end

--[[
	Sets the expiry time for the poll.
]]
function Poll.Prototype.setExpiry(self: Poll, expiry: number | datetime.DateTime): Poll
	if typeof(expiry) == "DateTime" then
		local object = expiry :: datetime.DateTime

		self.expiry = object.unixTimestampMillis
	else
		self.expiry = expiry :: number
	end

	return self
end

--[[
	Sets whether the poll allows multiple selections.
]]
function Poll.Prototype.setMultiselect(self: Poll, multiselect: boolean): Poll
	self.allowMultiselect = multiselect

	return self
end

--[[
	Sets the layout type for the poll.
]]
function Poll.Prototype.setLayoutType(self: Poll, layoutType: messageTypes.PollLayoutType): Poll
	self.layoutType = layoutType

	return self
end

--[[
	Builds and returns the Poll JSON that can be parsed by the Discord API.
]]
function Poll.Prototype.build(self: Poll): JSON
	return {
		question = self.question,
		answers = self.answers,
		expiry = self.expiry,
		allow_multiselect = self.allowMultiselect,
		layout_type = messageTypes.PollLayoutType[self.layoutType],
	}
end

--[[
	Responsible for creating a new Poll.

	```lua
	
	```
]]
function Poll.Interface.new(resource: {
	question: mediaBuilder.JSON?,
	answers: { answerBuilder.JSON }?,
	expiry: number?,
	allowMultiselect: boolean?,
	layoutType: messageTypes.PollLayoutType?,
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
	expiry: number,
	allowMultiselect: boolean,
	layoutType: messageTypes.PollLayoutType,
}

export type JSON = typeof(Poll.Prototype.build(nil :: any))

return Poll.Interface
