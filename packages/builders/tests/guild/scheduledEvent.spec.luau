local scheduledEvent = require("../../src/guild/scheduledEvent")
local scheduledEventRecurrenceRule = require("../../src/guild/scheduledEventRecurrenceRule")
local frktest = require("../../../../luau_packages/frktest")
local apiTypes = require("../../luau_packages/api_types")

local GuildScheduledEvent = scheduledEvent
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("GuildScheduledEvent builds a Stage event with required fields", function()
		local event = GuildScheduledEvent.new()
		event:setName("Concert")
		event:setPrivacyLevel("GuildOnly")
		event:setScheduledStartTime("2026-06-01T18:00:00Z")
		event:setEntityType("StageInstance")
		event:setChannelId("111222333444555666")
		local json = event:build()

		check.equal(json.name, "Concert")
		check.equal(json.privacy_level, apiTypes.guild.ScheduledEventPrivacyLevel.GuildOnly)
		check.equal(json.entity_type, apiTypes.guild.ScheduledEventEntityType.StageInstance)
		check.equal(json.channel_id, "111222333444555666")
		check.equal(json.scheduled_start_time, "2026-06-01T18:00:00Z")
	end)

	test.case("GuildScheduledEvent builds an External event with metadata and end time", function()
		local event = GuildScheduledEvent.new()
		event:setName("Outdoor Festival")
		event:setPrivacyLevel("GuildOnly")
		event:setScheduledStartTime("2026-07-04T12:00:00Z")
		event:setScheduledEndTime("2026-07-04T20:00:00Z")
		event:setEntityType("External")
		event:setEntityMetadata("Central Park, NYC")
		local json = event:build()

		check.equal(json.entity_type, apiTypes.guild.ScheduledEventEntityType.External)
		check.equal(json.entity_metadata ~= nil, true)
		local entity_metadata = json.entity_metadata
		assert(entity_metadata, "entity_metadata should not be nil")
		check.equal(entity_metadata.location, "Central Park, NYC")
		check.equal(json.scheduled_end_time, "2026-07-04T20:00:00Z")
		check.equal(json.channel_id, nil)
	end)

	test.case("GuildScheduledEvent build errors when name is missing", function()
		local event = GuildScheduledEvent.new()
		event:setPrivacyLevel("GuildOnly")
		event:setScheduledStartTime("2026-06-01T18:00:00Z")
		event:setEntityType("StageInstance")
		event:setChannelId("123")
		check.should_error(function()
			event:build()
			return
		end)
	end)

	test.case("GuildScheduledEvent build errors when entity type is missing", function()
		local event = GuildScheduledEvent.new()
		event:setName("Event"):setPrivacyLevel("GuildOnly"):setScheduledStartTime("2026-06-01T18:00:00Z")
		check.should_error(function()
			event:build()
			return
		end)
	end)

	test.case("GuildScheduledEvent External event errors without channel-free channel_id", function()
		local event = GuildScheduledEvent.new()
		event:setName("Outdoor"):setPrivacyLevel("GuildOnly"):setScheduledStartTime("2026-07-01T12:00:00Z")
		event:setEntityType("External")
		check.should_error(function()
			event:build()
			return
		end)
	end)

	test.case("GuildScheduledEvent Stage event errors without channel_id", function()
		local event = GuildScheduledEvent.new()
		event:setName("Stage"):setPrivacyLevel("GuildOnly"):setScheduledStartTime("2026-07-01T12:00:00Z")
		event:setEntityType("StageInstance")
		check.should_error(function()
			event:build()
			return
		end)
	end)

	test.case("GuildScheduledEvent privacy_level is always GuildOnly integer", function()
		local event = GuildScheduledEvent.new()
		event:setName("E"):setPrivacyLevel("GuildOnly"):setScheduledStartTime("2026-06-01T18:00:00Z")
		event:setEntityType("Voice"):setChannelId("123")
		local json = event:build()

		check.equal(type(json.privacy_level), "number")
		check.equal(json.privacy_level, 2)
	end)

	test.case("GuildScheduledEvent name rejects too-long strings", function()
		local event = GuildScheduledEvent.new()
		check.should_error(function()
			event:setName(string.rep("a", 101))
			return
		end)
	end)

	test.case("GuildScheduledEvent accepts optional recurrence rule", function()
		local rule = scheduledEventRecurrenceRule.new()
		rule:setStart("2026-06-01T18:00:00Z"):setFrequency("Weekly"):setInterval(1)
		local ruleJson = rule:build()

		local event = GuildScheduledEvent.new()
		event:setName("Weekly Event"):setPrivacyLevel("GuildOnly"):setScheduledStartTime("2026-06-01T18:00:00Z")
		event:setEntityType("Voice"):setChannelId("123"):setRecurrenceRule(ruleJson)
		local json = event:build()

		check.equal(json.recurrence_rule ~= nil, true)
	end)
end
