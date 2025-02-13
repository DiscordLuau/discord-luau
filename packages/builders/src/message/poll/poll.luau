--[[
	Implementation of discords Poll object as a Luau builder.	

	https://discord.com/developers/docs/resources/poll#poll-object
]]

local stdPolyfills = require("../../../lune_packages/std_polyfills")

local apiTypes = require("../../../lune_packages/api_types")

local mediaBuilder = require("./media")
local answerBuilder = require("./answer")

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
function Poll.Prototype.setExpiry(self: Poll, expiry: string | number | stdPolyfills.DateTime): Poll
	if typeof(expiry) == "DateTime" then
		local object = expiry :: stdPolyfills.DateTime

		self.expiry = tostring(object.unixTimestampMillis)
	else
		self.expiry = tostring(expiry)
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
function Poll.Prototype.setLayoutType(self: Poll, layoutType: apiTypes.PollLayoutType): Poll
	self.layoutType = layoutType

	return self
end

--[[
	Builds and returns the Poll JSON that can be parsed by the Discord API.
]]
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
