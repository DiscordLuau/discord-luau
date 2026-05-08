local poll = require("../../../src/message/poll/poll")
local media = require("../../../src/message/poll/media")
local answer = require("../../../src/message/poll/answer")
local frktest = require("../../../../../luau_packages/frktest")
local apiTypes = require("../../../luau_packages/api_types")

local Poll = poll
local test = frktest.test
local check = frktest.assert.check

local function makeQuestion()
	return media.new({ text = "What do you prefer?" }):build()
end

local answerCounter = 0
local function makeAnswer(text: string)
	answerCounter += 1
	return answer.new({ answerId = answerCounter, pollMedia = media.new({ text = text }):build() }):build()
end

return function()
	test.case("Poll builds with duration field (not expiry)", function()
		local p = Poll.new()
		p:setQuestion(makeQuestion())
		p:addAnswer(makeAnswer("Option A"))
		p:setDuration(24)
		p:setMultiselect(false)
		p:setLayoutType("Default")
		local json = p:build()

		check.equal(json.duration, 24)
		check.equal((json :: any).expiry, nil)
	end)

	test.case("Poll setDuration stores hours as integer", function()
		local p = Poll.new()
		p:setDuration(72)

		check.equal(p.duration, 72)
	end)

	test.case("Poll setDuration rejects zero or negative hours", function()
		local p = Poll.new()
		check.should_error(function()
			p:setDuration(0)
			return
		end)
		check.should_error(function()
			p:setDuration(-1)
			return
		end)
	end)

	test.case("Poll new() with allowMultiselect=false applies the value", function()
		local p = Poll.new({ allowMultiselect = false })

		check.equal(p.allowMultiselect, false)
	end)

	test.case("Poll new() with allowMultiselect=true applies the value", function()
		local p = Poll.new({ allowMultiselect = true })

		check.equal(p.allowMultiselect, true)
	end)

	test.case("Poll build errors when question is missing", function()
		local p = Poll.new()
		p:addAnswer(makeAnswer("A")):setMultiselect(false):setLayoutType("Default")
		check.should_error(function()
			p:build()
			return
		end)
	end)

	test.case("Poll build errors when no answers are provided", function()
		local p = Poll.new()
		p:setQuestion(makeQuestion()):setMultiselect(false):setLayoutType("Default")
		check.should_error(function()
			p:build()
			return
		end)
	end)

	test.case("Poll build errors when more than 10 answers are added", function()
		local p = Poll.new()
		p:setQuestion(makeQuestion())
		for i = 1, 10 do
			p:addAnswer(makeAnswer(tostring(i)))
		end
		check.should_error(function()
			p:addAnswer(makeAnswer("11th"))
			return
		end)
	end)

	test.case("Poll allow_multiselect is emitted in build output", function()
		local p = Poll.new()
		p:setQuestion(makeQuestion())
		p:addAnswer(makeAnswer("A"))
		p:setMultiselect(false)
		p:setLayoutType("Default")
		local json = p:build()

		check.equal(json.allow_multiselect, false)
	end)
end
