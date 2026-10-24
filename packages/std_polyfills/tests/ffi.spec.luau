local frktest = require("../../../luau_packages/frktest")

local stdPolyfills = require("../src")

local CYCLES = 20000
local BLOCK_SIZE = 23040
local MAX_GROWTH_KB = 8 * 1024

local test = frktest.test
local check = frktest.assert.check
local ffi = stdPolyfills.ffi

if stdPolyfills.runtime.getRuntime() ~= "Zune" then
	return function()
		test.skip.suite("Zune native memory pool", function() end)
	end
end

local function loadLibc(): FFILibrary?
	local types = ffi.getTypes()

	for _, libraryName in { "libc.so.6", "libSystem.B.dylib" } do
		local loaded, library = pcall(ffi.dlopen, libraryName, {
			malloc = { returns = types.pointer, args = { types.u64 } },
			free = { returns = types.void, args = { types.pointer } },
		})

		if loaded then
			return library
		end
	end

	return
end

local function residentKilobytes(): number?
	local readable, status = pcall(stdPolyfills.fileSystem.readFile, "/proc/self/status")

	if not readable then
		return
	end

	return tonumber(string.match(status, "VmRSS:%s+(%d+)"))
end

return function()
	test.suite("Zune native memory pool", function()
		test.case("a native allocation after a free gets a usable pointer", function()
			local libc = loadLibc()

			if not libc then
				return
			end

			for _ = 1, 20 do
				ffi.free(ffi.alloc(100, 1))

				local native = libc.malloc(100)
				local readable = pcall(native.readu8, native, 0)

				check.is_true(readable)

				libc.free(native)
			end
		end)

		test.case("a freed block is reused for the next allocation of its size class", function()
			local first = ffi.alloc(100, 1)

			ffi.free(first)

			local second = ffi.alloc(90, 1)

			check.equal(second, first)

			ffi.free(second)
		end)

		test.case("reused memory comes back zeroed", function()
			local pointer = ffi.alloc(32, 1)

			pointer:writeu8(0, 0xAB)
			pointer:writeu8(31, 0xCD)
			ffi.free(pointer)

			local reused = ffi.alloc(32, 1)

			check.equal(reused:readu8(0), 0)
			check.equal(reused:readu8(31), 0)

			ffi.free(reused)
		end)

		test.case("a pooled block comes back from alloc untagged", function()
			local block = ffi.alloc(8, 8)

			block:tag(ffi.getTypes().pointer:newTag("Stale"):tag())
			ffi.free(block)

			local reused = ffi.alloc(8, 8)

			check.is_true(rawequal(reused, block))
			check.equal(reused:tag(), 0)

			ffi.free(reused)
		end)

		test.case("freeing a block twice raises", function()
			local pointer = ffi.alloc(16, 1)

			ffi.free(pointer)

			check.should_error(function()
				ffi.free(pointer)

				return
			end)
		end)

		test.case("a duplicated buffer carries its contents", function()
			local source = buffer.fromstring("discord-luau")
			local pointer = ffi.dupe(source)
			local copy = buffer.create(buffer.len(source))

			pointer:read(0, copy, 0, buffer.len(source))

			check.equal(buffer.tostring(copy), "discord-luau")

			ffi.free(pointer)
		end)

		test.case("allocating and freeing in a loop does not grow memory", function()
			local before = residentKilobytes()

			for _ = 1, CYCLES do
				ffi.free(ffi.alloc(BLOCK_SIZE, 1))
			end

			local after = residentKilobytes()

			if before and after then
				check.is_true(after - before < MAX_GROWTH_KB)
			end
		end)
	end)
end
