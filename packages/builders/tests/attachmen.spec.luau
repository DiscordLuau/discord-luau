local attachments = require("../src/attachment")
local frktest = require("../../../lune_packages/frktest")

local Attachment = attachments

local test = frktest.test
local check = frktest.assert.check

return function()
	test.case("Attachment builder creates JSON with provided attachmentId", function()
		local attachment = Attachment.new()
		attachment:setId("test-attachment")
		local json = attachment:build()

		check.equal(json.id, "test-attachment")
	end)

	test.case("Attachment builder allows chaining of methods", function()
		local attachment = Attachment.new()
		check.should_not_error(function()
			attachment:setId("chained-attachment"):build()
			return attachment
		end)
	end)

	test.case("Attachment builder initializes correctly from resource", function()
		local attachment = Attachment.new({ attachmentId = "resource-attachment" })
		local json = attachment:build()

		check.equal(json.id, "resource-attachment")
	end)
end
