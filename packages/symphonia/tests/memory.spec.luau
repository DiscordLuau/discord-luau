local frktest = require("../../../luau_packages/frktest")
local stdPolyfills = require("../luau_packages/std_polyfills")

local symphonia = require("../src")
local SymphoniaBuffer = require("../src/buffer")

local FIXTURES = "packages/symphonia/tests/fixtures"
local CYCLES = 200
local MAX_READS = 200

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Symphonia native memory", function() end)
	end
end

local function readFixture(name: string): string
	return stdPolyfills.fileSystem.readFile(`{FIXTURES}/{name}`)
end

local function drain(read: () -> buffer?): number
	local itemCount = 0
	local item = read()

	while item do
		if itemCount >= MAX_READS then
			error(`the decoder did not end within {MAX_READS} reads`)
		end

		itemCount += 1
		item = read()
	end

	return itemCount
end

local function openCount(): number
	return symphonia.load().symphonia_open_count()
end

local function countNativeMemory(work: () -> ()): (number, number)
	local originalAlloc = SymphoniaBuffer.alloc
	local originalFree = SymphoniaBuffer.free
	local allocations = 0
	local frees = 0
	local succeeded, workError = pcall(function()
		SymphoniaBuffer.alloc = function(size: number)
			allocations += 1

			return originalAlloc(size)
		end
		SymphoniaBuffer.free = function(pointer: FFIPointer)
			frees += 1

			originalFree(pointer)
		end

		work()
	end)

	SymphoniaBuffer.alloc = originalAlloc
	SymphoniaBuffer.free = originalFree

	assert(succeeded, workError)

	return allocations, frees
end

return function()
	test.suite("Symphonia native memory", function()
		test.case("loads libsymphonia with ABI version 2", function()
			check.equal(symphonia.load().symphonia_abi_version(), 2)
		end)

		test.case(`{CYCLES} open, read and destroy cycles return the open count to its start`, function()
			local wav = readFixture("tone.wav")
			local opus = readFixture("tone.opus")
			local flacPath = `{FIXTURES}/tone.flac`
			local countBefore = openCount()

			for cycle = 1, CYCLES do
				local kind = cycle % 3
				local decoder = if kind == 0
					then symphonia.decoder.fromBuffer(wav)
					elseif kind == 1 then symphonia.decoder.fromBuffer(opus)
					else symphonia.decoder.fromFile(flacPath)

				if kind == 0 then
					drain(function()
						return decoder:read()
					end)
				elseif kind == 1 then
					drain(function()
						return decoder:readPacket()
					end)
				else
					decoder:read()
				end

				decoder:destroy()
			end

			check.equal(openCount(), countBefore)
		end)

		test.case("reading allocates no native memory", function()
			local decoder = symphonia.decoder.fromBuffer(readFixture("tone.mp3"))
			local packetDecoder = symphonia.decoder.fromBuffer(readFixture("tone.opus"))
			local allocations = countNativeMemory(function()
				drain(function()
					return decoder:read()
				end)
				drain(function()
					return packetDecoder:readPacket()
				end)
			end)

			check.equal(allocations, 0)

			decoder:destroy()
			packetDecoder:destroy()
		end)

		test.case("a decoder frees every native buffer it allocates", function()
			local bytes = readFixture("tone.flac")
			local allocations, frees = countNativeMemory(function()
				local decoder = symphonia.decoder.fromBuffer(bytes)

				decoder:read()
				decoder:destroy()
				decoder:destroy()
			end)

			check.greater(allocations, 0)
			check.equal(frees, allocations)
		end)

		test.case("a failed open frees what it allocated", function()
			local countBefore = openCount()
			local allocations, frees = countNativeMemory(function()
				pcall(symphonia.decoder.fromBuffer, "not audio at all")
			end)

			check.greater(allocations, 0)
			check.equal(frees, allocations)
			check.equal(openCount(), countBefore)
		end)

		test.case("an invalid log level opens nothing and keeps no memory", function()
			local bytes = readFixture("tone.wav")
			local countBefore = openCount()
			local succeeded: boolean?
			local failure: unknown
			local allocations, frees = countNativeMemory(function()
				succeeded, failure = pcall(symphonia.decoder.fromBuffer, bytes, { logLevel = "Bogus" :: any })
			end)

			check.equal(succeeded, false)
			check.not_nil((string.find(tostring(failure), "Invalid log level: Bogus", 1, true)))
			check.equal(frees, allocations)
			check.equal(openCount(), countBefore)
		end)

		test.case("input that is not a buffer or string opens nothing and keeps no memory", function()
			local countBefore = openCount()
			local succeeded: boolean?
			local allocations, frees = countNativeMemory(function()
				succeeded = pcall(symphonia.decoder.fromBuffer, 42 :: any)
			end)

			check.equal(succeeded, false)
			check.equal(frees, allocations)
			check.equal(openCount(), countBefore)
		end)

		test.case("a failure while building a decoder closes its session and frees its memory", function()
			local bytes = readFixture("tone.flac")
			local originalRead = SymphoniaBuffer.read
			local countBefore = openCount()
			local succeeded: boolean?
			local failure: unknown
			local allocations, frees = countNativeMemory(function()
				SymphoniaBuffer.read = function(_pointer: FFIPointer, _length: number): buffer
					error("simulated failure while building the decoder", 0)
				end
				succeeded, failure = pcall(symphonia.decoder.fromBuffer, bytes)
				SymphoniaBuffer.read = originalRead
			end)

			check.equal(succeeded, false)
			check.equal(failure, "simulated failure while building the decoder")
			check.greater(allocations, 0)
			check.equal(frees, allocations)
			check.equal(openCount(), countBefore)
		end)

		test.case("a path with a NUL byte opens nothing and keeps no memory", function()
			local countBefore = openCount()
			local succeeded: boolean?
			local result: unknown
			local allocations, frees = countNativeMemory(function()
				succeeded, result = pcall(symphonia.decoder.fromFile, `{FIXTURES}/tone.flac\0ignored.mp3`)
			end)

			if succeeded then
				(result :: symphonia.Decoder):destroy()
			end

			check.equal(succeeded, false)
			check.equal(result, "could not open audio: the path contains a NUL byte")
			check.equal(allocations, 0)
			check.equal(frees, 0)
			check.equal(openCount(), countBefore)
		end)
	end)
end
