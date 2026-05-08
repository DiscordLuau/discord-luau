local stageInstance = require("../../src/guild/stageInstance")
local frktest = require("../../../../luau_packages/frktest")
local apiTypes = require("../../luau_packages/api_types")

local StageInstance = stageInstance
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("StageInstance builds with required fields", function()
		local si = StageInstance.new()
		si:setChannelId("111222333"):setTopic("Welcome to the stage!")
		local json = si:build()

		check.equal(json.channel_id, "111222333")
		check.equal(json.topic, "Welcome to the stage!")
	end)

	test.case("StageInstance privacy_level maps to integer", function()
		local si = StageInstance.new()
		si:setChannelId("111"):setTopic("Topic"):setPrivacyLevel("GuildOnly")
		local json = si:build()

		check.equal(json.privacy_level, apiTypes.guild.StageInstancePrivacyLevel.GuildOnly)
		check.equal(type(json.privacy_level), "number")
	end)

	test.case("StageInstance Public privacy_level maps correctly", function()
		local si = StageInstance.new()
		si:setChannelId("111"):setTopic("Topic"):setPrivacyLevel("Public")
		local json = si:build()

		check.equal(json.privacy_level, apiTypes.guild.StageInstancePrivacyLevel.Public)
	end)

	test.case("StageInstance build errors when channel_id is missing", function()
		local si = StageInstance.new()
		si:setTopic("Topic")
		check.should_error(function()
			si:build()
			return
		end)
	end)

	test.case("StageInstance build errors when topic is missing", function()
		local si = StageInstance.new()
		si:setChannelId("111")
		check.should_error(function()
			si:build()
			return
		end)
	end)

	test.case("StageInstance topic rejects empty string", function()
		local si = StageInstance.new()
		check.should_error(function()
			si:setTopic("")
			return
		end)
	end)

	test.case("StageInstance topic rejects strings longer than 120 characters", function()
		local si = StageInstance.new()
		check.should_error(function()
			si:setTopic(string.rep("a", 121))
			return
		end)
	end)

	test.case("StageInstance optional fields are nil when not set", function()
		local si = StageInstance.new()
		si:setChannelId("111"):setTopic("Topic")
		local json = si:build()

		check.equal(json.privacy_level, nil)
		check.equal(json.send_start_notification, nil)
		check.equal(json.guild_scheduled_event_id, nil)
	end)

	test.case("StageInstance optional fields are passed through", function()
		local si = StageInstance.new()
		si:setChannelId("111"):setTopic("Topic")
		si:setSendStartNotification(true):setGuildScheduledEventId("999888777")
		local json = si:build()

		check.equal(json.send_start_notification, true)
		check.equal(json.guild_scheduled_event_id, "999888777")
	end)
end
