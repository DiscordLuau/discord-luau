local interaction = require("../../src/interaction/interaction")
local frktest = require("../../../../luau_packages/frktest")

local Interaction = interaction
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Interaction builds a CHAT_INPUT command with required fields", function()
		local cmd = Interaction.new()
		cmd:setName("my-command")
			:setDescription("Does something")
			:addIntegrationType("GuildInstall")
			:addContext("Guild")
		local json = cmd:build()

		check.equal(json.name, "my-command")
		check.equal(json.description, "Does something")
	end)

	test.case("Interaction setName rejects uppercase letters", function()
		local cmd = Interaction.new()
		check.should_error(function()
			cmd:setName("MyCommand")
			return
		end)
	end)

	test.case("Interaction setName allows hyphens and underscores", function()
		local cmd = Interaction.new()
		check.should_not_error(function()
			cmd:setName("my_command-name")
			return
		end)
	end)

	test.case("Interaction setName rejects names longer than 32 characters", function()
		local cmd = Interaction.new()
		check.should_error(function()
			cmd:setName(string.rep("a", 33))
			return
		end)
	end)

	test.case("Interaction build rejects USER command with description set", function()
		local cmd = Interaction.new()
		cmd:setName("my-command")
			:setType("User")
			:setDescription("should not be here")
			:addIntegrationType("GuildInstall")
			:addContext("Guild")
		check.should_error(function()
			cmd:build()
			return
		end)
	end)

	test.case("Interaction build rejects USER command with empty string description", function()
		local cmd = Interaction.new()
		cmd:setName("my-command"):setType("User"):addIntegrationType("GuildInstall"):addContext("Guild")
		cmd.description = ""
		check.should_error(function()
			cmd:build()
			return
		end)
	end)

	test.case("Interaction build rejects CHAT_INPUT command without description", function()
		local cmd = Interaction.new()
		cmd:setName("my-command"):addIntegrationType("GuildInstall"):addContext("Guild")
		check.should_error(function()
			cmd:build()
			return
		end)
	end)

	test.case("Interaction build rejects command with no integration types", function()
		local cmd = Interaction.new()
		cmd:setName("my-command"):setDescription("desc"):addContext("Guild")
		check.should_error(function()
			cmd:build()
			return
		end)
	end)

	test.case("Interaction build rejects command with no contexts", function()
		local cmd = Interaction.new()
		cmd:setName("my-command"):setDescription("desc"):addIntegrationType("GuildInstall")
		check.should_error(function()
			cmd:build()
			return
		end)
	end)

	test.case("Interaction nsfw=false in new() is not skipped", function()
		local cmd = Interaction.new({ nsfw = false } :: any)
		check.equal(cmd.nsfw, nil)
	end)
end
