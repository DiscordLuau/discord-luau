--[=[
	@class Classes.Message.Poll
	@__index Prototype

	Implementation of the Discord Poll class in Luau

	https://discord.com/developers/docs/resources/poll#poll-object
]=]

--[=[
	@prop question Classes.Message.PollMediaObject
	@within Classes.Message.Poll
	The question being asked in the poll
]=]

--[=[
	@prop answers { Classes.Message.PollAnswer }
	@within Classes.Message.Poll
	Array of possible answers for the poll
]=]

--[=[
	@prop expiry DateTime
	@within Classes.Message.Poll
	When the poll will expire and close for voting
]=]

--[=[
	@prop allowMultiselect boolean
	@within Classes.Message.Poll
	Whether users can select multiple answers
]=]

--[=[
	@prop layoutType Classes.PollLayoutType
	@within Classes.Message.Poll
	The layout style used to display the poll
]=]

--[=[
	@prop results Classes.Message.PollResults
	@within Classes.Message.Poll
	The current results of the poll
]=]

local stdPolyfills = require("../../../luau_packages/std_polyfills")

local apiTypes = require("../../../luau_packages/api_types")

local answer = require("./answer")
local mediaObject = require("./mediaObject")
local results = require("./results")

local Poll = {}

Poll.Interface = {}
Poll.Prototype = {}

--[=[
	@within Classes.Message.Poll
	@private

	Responsible for syncing data to this poll object. This is typically called by the API when this object is
	created or updated.
]=]
function Poll.Prototype.sync(self: Poll, pollData: apiTypes.PollObject)
	self.question = mediaObject.new(pollData.question)

	local answerArray = {}

	for _, answerData in pollData.answers do
		table.insert(answerArray, answer.new(answerData))
	end

	self.answers = answerArray

	self.expiry = pollData.expiry and stdPolyfills.datetime.fromIsoDate(pollData.expiry)

	self.allowMultiselect = pollData.allow_multiselect

	self.layoutType = (pollData.layout_type == 1 and "Default") :: apiTypes.PollLayoutType

	self.results = pollData.results and results.new(pollData.results)
end

--[=[
	@within Classes.Message.Poll
	@private

	Responsible for constructing this class.
]=]
function Poll.Interface.new(pollData: apiTypes.PollObject): Poll
	local self = setmetatable({} :: Poll, { __index = Poll.Prototype })

	self:sync(pollData)

	return self
end

export type Poll = typeof(Poll.Prototype) & {
	question: mediaObject.MediaObject,
	answers: { answer.Answer },
	expiry: stdPolyfills.DateTime?,
	allowMultiselect: boolean,
	layoutType: apiTypes.PollLayoutType,
	results: results.Results?,
}

return Poll.Interface
