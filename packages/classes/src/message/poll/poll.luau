--[=[
	@class Classes.Poll
	@__index Prototype

	Implementation of the Discord Poll class in Luau

	https://discord.com/developers/docs/resources/poll#poll-object
]=]

local stdPolyfills = require("../../../lune_packages/std_polyfills")

local apiTypes = require("../../../lune_packages/api_types")

local answer = require("./answer")
local mediaObject = require("./mediaObject")
local results = require("./results")

local Poll = {}

Poll.Interface = {}
Poll.Prototype = {}

--[=[
	@within Classes.Poll
	@private

	Responsible for syncing data to this poll object. This is typically called by the API when this object is
	created or updated.
]=]
function Poll.Prototype.sync(self: Poll, pollData: apiTypes.PollObject)
	--[=[
		@prop question Classes.MediaObject
		@within Classes.Poll
		The question being asked in the poll
	]=]
	self.question = mediaObject.new(pollData.question)

	--[=[
		@prop answers { Classes.Answer }
		@within Classes.Poll
		Array of possible answers for the poll
	]=]
	local answerArray = {}

	for _, answerData in pollData.answers do
		table.insert(answerArray, answer.new(answerData))
	end

	self.answers = answerArray

	--[=[
		@prop expiry DateTime
		@within Classes.Poll
		When the poll will expire and close for voting
	]=]
	self.expiry = pollData.expiry and stdPolyfills.datetime.fromIsoDate(pollData.expiry)

	--[=[
		@prop allowMultiselect boolean
		@within Classes.Poll
		Whether users can select multiple answers
	]=]
	self.allowMultiselect = pollData.allow_multiselect

	--[=[
		@prop layoutType Classes.PollLayoutType
		@within Classes.Poll
		The layout style used to display the poll
	]=]
	self.layoutType = (pollData.layout_type == 1 and "Default") :: apiTypes.PollLayoutType

	--[=[
		@prop results Classes.Results
		@within Classes.Poll
		The current results of the poll
	]=]
	self.results = pollData.results and results.new(pollData.results)
end

--[=[
	@within Classes.Poll
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
