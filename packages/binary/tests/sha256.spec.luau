local frktest = require("../../../luau_packages/frktest")

local sha256 = require("../src/sha256")

local test = frktest.test
local check = frktest.assert.check

local function digest(message: string): string
	return sha256.new():update(message):hex()
end

local function everyByteValue(length: number): string
	local bytes = buffer.create(length)

	for index = 0, length - 1 do
		buffer.writeu8(bytes, index, index % 256)
	end

	return buffer.tostring(bytes)
end

return function()
	test.suite("sha256", function()
		test.case("hashes an empty message", function()
			check.equal(digest(""), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
		end)

		test.case("hashes ascii text", function()
			check.equal(digest("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
		end)

		test.case("hashes raw bytes above 0x7f", function()
			check.equal(
				digest(everyByteValue(1024 * 1024)),
				"fbbab289f7f94b25736c58be46a994c441fd02552cc6022352e3d86d2fab7c83"
			)
		end)
	end)
end
