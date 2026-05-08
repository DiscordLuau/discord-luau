local updateVoiceState = require("../../src/voice/updateVoiceState")
local frktest = require("../../../../luau_packages/frktest")

local UpdateVoiceState = updateVoiceState
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("UpdateVoiceState builds with required fields", function()
		local uvs = UpdateVoiceState.new()
		uvs:setGuildId("123456789"):setSelfMute(false):setSelfDeaf(false)
		local json = uvs:build()

		check.equal(json.guild_id, "123456789")
		check.equal(json.self_mute, false)
		check.equal(json.self_deaf, false)
	end)

	test.case("UpdateVoiceState build errors when guild_id is missing", function()
		local uvs = UpdateVoiceState.new()
		uvs:setSelfMute(false):setSelfDeaf(false)
		check.should_error(function()
			uvs:build()
			return
		end)
	end)

	test.case("UpdateVoiceState build errors when self_mute is missing", function()
		local uvs = UpdateVoiceState.new()
		uvs:setGuildId("123"):setSelfDeaf(false)
		check.should_error(function()
			uvs:build()
			return
		end)
	end)

	test.case("UpdateVoiceState build errors when self_deaf is missing", function()
		local uvs = UpdateVoiceState.new()
		uvs:setGuildId("123"):setSelfMute(false)
		check.should_error(function()
			uvs:build()
			return
		end)
	end)

	test.case("UpdateVoiceState channel_id is nil when not set (stays in channel)", function()
		local uvs = UpdateVoiceState.new()
		uvs:setGuildId("123"):setSelfMute(false):setSelfDeaf(false)
		local json = uvs:build()

		check.equal(json.channel_id, nil)
	end)

	test.case("UpdateVoiceState channel_id nil disconnects from voice", function()
		local uvs = UpdateVoiceState.new()
		uvs:setGuildId("123"):setSelfMute(false):setSelfDeaf(false):setChannelId(nil)
		local json = uvs:build()

		check.equal(json.channel_id, nil)
	end)

	test.case("UpdateVoiceState channel_id is passed through", function()
		local uvs = UpdateVoiceState.new()
		uvs:setGuildId("123"):setSelfMute(true):setSelfDeaf(false):setChannelId("voice-channel-id")
		local json = uvs:build()

		check.equal(json.channel_id, "voice-channel-id")
	end)

	test.case("UpdateVoiceState self_mute=true is emitted correctly", function()
		local uvs = UpdateVoiceState.new()
		uvs:setGuildId("123"):setSelfMute(true):setSelfDeaf(false)
		local json = uvs:build()

		check.equal(json.self_mute, true)
	end)
end
