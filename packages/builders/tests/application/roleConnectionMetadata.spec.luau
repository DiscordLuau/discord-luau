local roleConnectionMetadata = require("../../src/application/roleConnectionMetadata")
local frktest = require("../../../../luau_packages/frktest")
local apiTypes = require("../../luau_packages/api_types")

local RoleConnectionMetadata = roleConnectionMetadata
local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("RoleConnectionMetadata builds with required fields", function()
		local rcm = RoleConnectionMetadata.new()
		rcm:setType("IntegerLessThanOrEqual")
			:setKey("game_level")
			:setName("Game Level")
			:setDescription("Your level in the game")
		local json = rcm:build()

		check.equal(json.type, apiTypes.application.ApplicationRoleConnectionMetadataType.IntegerLessThanOrEqual)
		check.equal(json.key, "game_level")
		check.equal(json.name, "Game Level")
		check.equal(json.description, "Your level in the game")
		check.equal(type(json.type), "number")
	end)

	test.case("RoleConnectionMetadata type maps to integer", function()
		local rcm = RoleConnectionMetadata.new()
		rcm:setType("BooleanEqual"):setKey("is_verified"):setName("Verified"):setDescription("Is verified")
		local json = rcm:build()

		check.equal(json.type, apiTypes.application.ApplicationRoleConnectionMetadataType.BooleanEqual)
		check.equal(json.type, 7)
	end)

	test.case("RoleConnectionMetadata key rejects invalid characters", function()
		local rcm = RoleConnectionMetadata.new()
		check.should_error(function()
			rcm:setKey("My Key!")
			return
		end)
	end)

	test.case("RoleConnectionMetadata key rejects uppercase", function()
		local rcm = RoleConnectionMetadata.new()
		check.should_error(function()
			rcm:setKey("MyKey")
			return
		end)
	end)

	test.case("RoleConnectionMetadata key accepts lowercase and underscores", function()
		local rcm = RoleConnectionMetadata.new()
		check.should_not_error(function()
			rcm:setKey("game_level_123")
			return
		end)
	end)

	test.case("RoleConnectionMetadata key rejects empty string", function()
		local rcm = RoleConnectionMetadata.new()
		check.should_error(function()
			rcm:setKey("")
			return
		end)
	end)

	test.case("RoleConnectionMetadata key rejects strings longer than 50 characters", function()
		local rcm = RoleConnectionMetadata.new()
		check.should_error(function()
			rcm:setKey(string.rep("a", 51))
			return
		end)
	end)

	test.case("RoleConnectionMetadata description rejects strings longer than 200 characters", function()
		local rcm = RoleConnectionMetadata.new()
		check.should_error(function()
			rcm:setDescription(string.rep("a", 201))
			return
		end)
	end)

	test.case("RoleConnectionMetadata build errors when type is missing", function()
		local rcm = RoleConnectionMetadata.new()
		rcm:setKey("k"):setName("N"):setDescription("D")
		check.should_error(function()
			rcm:build()
			return
		end)
	end)

	test.case("RoleConnectionMetadata build errors when key is missing", function()
		local rcm = RoleConnectionMetadata.new()
		rcm:setType("BooleanEqual"):setName("N"):setDescription("D")
		check.should_error(function()
			rcm:build()
			return
		end)
	end)

	test.case("RoleConnectionMetadata optional localizations are passed through", function()
		local rcm = RoleConnectionMetadata.new()
		rcm:setType("IntegerEqual"):setKey("score"):setName("Score"):setDescription("Game score")
		rcm:setNameLocalizations({ ["en-US"] = "Score", ["fr"] = "Score" })
		rcm:setDescriptionLocalizations({ ["en-US"] = "Your game score" })
		local json = rcm:build()

		check.equal(json.name_localizations ~= nil, true)
		check.equal(json.description_localizations ~= nil, true)
	end)
end
