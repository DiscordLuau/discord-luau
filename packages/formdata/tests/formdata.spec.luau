local frktest = require("../../../lune_packages/frktest")

local formdata = require("../src")

local RAW_FORM_DATA_CASE =
	'--TEST-CASE\r\nContent-Disposition: form-data; name="example"\r\nContent-Type: application/octet-stream\r\n\r\nvalue\r\n--TEST-CASE--\r\n'

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("is able to construct an formdata object", function()
		local object = formdata.new()

		check.not_nil(object)
	end)

	test.case("is able to add data to the formdata object", function()
		local object = formdata.new()

		object:append("example", "value")

		check.greater(#object.entries, 0)
		check.is_true(object:has("example"))
	end)

	test.case("is able to construct the raw formdata implementation", function()
		local object = formdata.new()

		object.boundary = "TEST-CASE"

		object:append("example", "value")

		local bodyImplementation = object:getBody()
		local headerImplementation = object:getHeader()

		check.truthy(bodyImplementation)
		check.truthy(headerImplementation)

		check.equal(bodyImplementation, RAW_FORM_DATA_CASE)
	end)

	test.case("is able to parse raw formdata into a formdata object", function()
		local object = formdata.parse(RAW_FORM_DATA_CASE, "multipart/form-data; boundary=TEST-CASE")

		check.truthy(object)
		check.table.contains(object.entries, {
			name = "example",
			value = "value",
		})
	end)

	test.case("is able to parse a newly created formdata object", function()
		local formdataObject = formdata.new()

		for index = 1, 50 do
			formdataObject:append("example", "value", `example{index}.txt`)
		end

		local rawFormData = formdataObject:getBody()
		local rawFormHeader = formdataObject:getHeader()

		local parsedFormData = formdata.parse(rawFormData, rawFormHeader)

		check.truthy(parsedFormData)

		for index = 1, 50 do
			check.table.contains(parsedFormData.entries, {
				name = "example",
				value = "value",
				filename = `example{index}.txt`,
			})
		end
	end)
end
