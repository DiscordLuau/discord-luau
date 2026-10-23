local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local Opus = require("../src")
local OpusBuffer = require("../src/buffer")

local SAMPLE_RATE = 48000
local CHANNELS = 2
local FRAME_SIZE = 960
local FRAMES = 20

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Native memory", function() end)
	end
end

local function makeToneFrame(): buffer
	local frame = buffer.create(FRAME_SIZE * CHANNELS * 2)

	for index = 0, FRAME_SIZE * CHANNELS - 1 do
		buffer.writei16(frame, index * 2, math.floor(math.sin(index / 20) * 8000))
	end

	return frame
end

local function countNativeCells(work: () -> ()): (number, number)
	local originalAlloc = OpusBuffer.alloc
	local originalDupe = OpusBuffer.dupe
	local originalFree = OpusBuffer.free
	local allocations = 0
	local frees = 0
	local succeeded, workError = pcall(function()
		OpusBuffer.alloc = function(size: number)
			allocations += 1

			return originalAlloc(size)
		end
		OpusBuffer.dupe = function(source: buffer)
			allocations += 1

			return originalDupe(source)
		end
		OpusBuffer.free = function(pointer: FFIPointer)
			frees += 1

			originalFree(pointer)
		end

		work()
	end)

	OpusBuffer.alloc = originalAlloc
	OpusBuffer.dupe = originalDupe
	OpusBuffer.free = originalFree

	assert(succeeded, workError)

	return allocations, frees
end

local function countNativeAllocations(work: () -> ()): number
	local allocations = countNativeCells(work)

	return allocations
end

return function()
	test.suite("Native memory", function()
		test.case("decoding reuses its native buffers", function()
			local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)
			local decoder = Opus.decoder.new(SAMPLE_RATE, CHANNELS)
			local packet = encoder:encode(makeToneFrame())
			local allocations = countNativeAllocations(function()
				for _ = 1, FRAMES do
					decoder:decode(packet)
					decoder:decodePLC()
				end
			end)

			check.equal(allocations, 0)

			encoder:destroy()
			decoder:destroy()
		end)

		test.case("encoding reuses its native buffers", function()
			local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)
			local frame = makeToneFrame()
			local allocations = countNativeAllocations(function()
				for _ = 1, FRAMES do
					encoder:encode(frame)
				end
			end)

			check.equal(allocations, 0)

			encoder:destroy()
		end)

		test.case("reading a setting allocates a cell and frees every one", function()
			local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)
			local allocations, frees = countNativeCells(function()
				for _ = 1, FRAMES do
					encoder:getBitrate()
					encoder:getSignal()
				end
			end)

			check.equal(allocations, FRAMES * 2)
			check.equal(frees, allocations)

			encoder:destroy()
		end)

		test.case("forward error correction recovers exactly one 20 ms frame", function()
			local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)
			local decoder = Opus.decoder.new(SAMPLE_RATE, CHANNELS)
			local packet = encoder:encode(makeToneFrame())

			decoder:decode(packet)

			check.equal(buffer.len(decoder:decodeFec(packet)), FRAME_SIZE * CHANNELS * 2)

			encoder:destroy()
			decoder:destroy()
		end)

		test.case("a destroyed decoder raises an error instead of crashing", function()
			local decoder = Opus.decoder.new(SAMPLE_RATE, CHANNELS)
			local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)
			local packet = encoder:encode(makeToneFrame())

			decoder:destroy()

			check.should_error(function()
				decoder:decode(packet)

				return
			end)
			check.should_error(function()
				decoder:decodePLC()

				return
			end)

			encoder:destroy()
		end)

		test.case("a destroyed encoder raises an error instead of crashing", function()
			local encoder = Opus.encoder.new(SAMPLE_RATE, CHANNELS, Opus.application.voip)
			local frame = makeToneFrame()

			encoder:destroy()

			check.should_error(function()
				encoder:encode(frame)

				return
			end)
		end)
	end)
end
