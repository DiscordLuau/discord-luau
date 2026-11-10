local frktest = require("../../../luau_packages/frktest")

local modal = require("../src/interaction/types/modal")

local LABEL_COMPONENTS = {
	{ id = 1, type = 10 },
	{ id = 2, type = 18, component = { value = "dasd", type = 4, id = 3, custom_id = "colour" } },
}

local ACTION_ROW_COMPONENTS = {
	{ id = 1, type = 1, components = { { value = "eeee", type = 4, id = 2, custom_id = "colour" } } },
}

local test = frktest.test
local check = frktest.assert.check

local function modalSubmit(components: { any })
	return modal.new(
		{} :: any,
		{
			id = "1",
			application_id = "2",
			type = 5,
			token = "token",
			version = 1,
			app_permissions = "0",
			data = { custom_id = "modal", components = components },
		} :: any
	)
end

return function()
	test.case("getContent reads a text input inside a Label", function()
		check.equal(modalSubmit(LABEL_COMPONENTS):getContent("colour"), "dasd")
	end)

	test.case("getContent reads a text input inside an action row", function()
		check.equal(modalSubmit(ACTION_ROW_COMPONENTS):getContent("colour"), "eeee")
	end)

	test.case("getContent returns nil for a custom ID the modal does not have", function()
		check.equal(modalSubmit(LABEL_COMPONENTS):getContent("missing"), nil)
		check.equal(modalSubmit(ACTION_ROW_COMPONENTS):getContent("missing"), nil)
	end)
end
