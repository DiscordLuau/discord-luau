--[=[
	@class Symphonia.Sys

	Raw FFI bindings for libsymphonia, the Rust wrapper around [Symphonia](https://github.com/pdeljanov/Symphonia) built
	from this package's `native/` folder. Prefer `Symphonia.Decoder` over calling the library directly.

	`opus` and `sodium` load their library when they are required, and `dave` swaps in a stub module without FFI.
	Symphonia loads lazily instead: requiring it, or `audio`, never downloads a 2 to 3 MB library that a bot which
	plays no files would never use. `load` loads it on its first call.
]=]

--[=[
	@prop library Lib?
	@within Symphonia.Sys
	@private

	The loaded library, nil until a `load` succeeds.
]=]

--[=[
	@prop loading boolean
	@within Symphonia.Sys
	@private

	Whether a `load` is in flight.
]=]

--[=[
	@prop waitingThreads { thread }
	@within Symphonia.Sys
	@private

	The threads waiting on the load in flight, resumed with its result.
]=]

--[=[
	@prop logger logger.Logger
	@within Symphonia.Sys

	The loader's logger, named `Symphonia` and at `Info`.
]=]

--[=[
	@prop infoField { sampleRate: number, channels: number, isOpus: number, durationMilliseconds: number, skippedPackets: number, isFailed: number, endedEarly: number, state: number }
	@within Symphonia.Sys

	The field numbers `symphonia_info` takes. `endedEarly` (6) is `1` when decoding ended short of the length the file
	states, because the file is truncated or damaged packets were skipped. `state` (7) is `0` while a stream probes,
	`1` once open, `2` at the end and `3` after a failure; `isFailed` (5) is `1` exactly when it is `3`.
]=]

--[=[
	@prop describeField { codec: number, container: number, failure: number }
	@within Symphonia.Sys

	The field numbers `symphonia_describe` takes. `failure` (2) is the failure text, empty until the state is `3`.
]=]

local binary = require("../luau_packages/binary")
local logger = require("../luau_packages/logger")
local stdPolyfills = require("../luau_packages/std_polyfills")

local CHECKSUMS: { [string]: string } = {
	["linux-arm64"] = "sha256:cfd78103a5d48f67d1532187bff63a6f84efb03f7023e9b63c92a7e048c45fb3",
	["linux-x64"] = "sha256:3776ba3387155e4b8a25012dba5c5bf597686dea530ef0c3519a26bccb88203a",
	["macos-arm64"] = "sha256:6b3780d1816db61d193e2794370ba2ec10abd0fbc50d7670f9e218d48a2ad14a",
	["macos-x64"] = "sha256:4b75baebded6d54589cffde7fb89f1f1bb5ade370cb4a857e3bfffe92db17beb",
	["windows-x64"] = "sha256:5d9a43c6d63eebb2e41e79554c020aeaa87a0e046ccad184e5573c8cb4dbd9a8",
	["windows-x86"] = "sha256:7384fc3a299312a9ccdd8f8e74b38db5053c11c45ca957d8002afad35ead1f49",
}
local ABI_VERSION = 3

local Sys = {
	library = nil :: Lib?,
	loading = false,
	waitingThreads = {} :: { thread },
	logger = logger.new("Symphonia", "Info"),

	ABI_VERSION = ABI_VERSION,
	OUTPUT_SAMPLE_RATE = 48000,
	OUTPUT_CHANNELS = 2,
	BYTES_PER_FRAME = 4,
	FLOAT_BYTES_PER_FRAME = 8,
	ERROR_CAPACITY = 1024,
	NAME_CAPACITY = 64,
	READ_FRAMES = 4800,
	MAX_VOLUME = 4,
	MAX_PACKET_SIZE = 8000,
	NOT_READY = -2,
	FULL = -3,

	infoField = {
		sampleRate = 0,
		channels = 1,
		isOpus = 2,
		durationMilliseconds = 3,
		skippedPackets = 4,
		isFailed = 5,
		endedEarly = 6,
		state = 7,
	},

	describeField = {
		codec = 0,
		container = 1,
		failure = 2,
	},
}

--[=[
	@within Symphonia.Sys
	@yields

	Returns the library, loading it on the first call and caching it. The load runs in its own deferred thread and
	every caller waits for it, so the first call always yields, and callers that arrive while it is in flight share its
	result; a caller cancelled while it waits never strands the others. The first load may download the library and
	checks its sha256, which takes about 360 ms of Luau for a 3 MB file; call it at startup to take that cost early. A
	failed load is not cached, so the next call tries again.

	Raises `Symphonia requires FFI which is not available on this runtime` without FFI, and
	`libsymphonia ABI version <n> does not match 3; update the symphonia package` for a library this package cannot use.
]=]
function Sys.load(): Lib
	local library = Sys.library

	if not library then
		if not Sys.loading then
			Sys.loading = true
			stdPolyfills.task.defer(Sys.loadOnce)
		end

		library = Sys.waitForLoad()
	end

	return library :: Lib
end

--[=[
	@within Symphonia.Sys
	@private
	@yields

	Waits for the load in flight and returns its library, or raises its error.
]=]
function Sys.waitForLoad(): Lib
	local thread = coroutine.running()

	table.insert(Sys.waitingThreads, thread)
	Sys.logger:debug(`waiting for the libsymphonia load in flight`)

	local succeeded, result = coroutine.yield()

	if not succeeded then
		error(result, 0)
	end

	return result
end

--[=[
	@within Symphonia.Sys
	@private
	@yields

	Runs the load in its own thread, caches the library when it succeeds, and resumes every thread still waiting with
	the result. A failure is raised in every waiting caller and not cached. A waiter that is no longer suspended, such
	as one cancelled while it waited, is skipped.
]=]
function Sys.loadOnce()
	local succeeded, result = pcall(Sys.openLibrary)
	local waitingThreads = Sys.waitingThreads

	Sys.loading = false
	Sys.waitingThreads = {}
	Sys.library = if succeeded then result else nil

	if not succeeded then
		Sys.logger:debug(`loading libsymphonia failed, and the next load tries again: {result}`)
	end

	for _, thread in waitingThreads do
		local status = coroutine.status(thread)

		if status ~= "suspended" then
			Sys.logger:debug(`skipped a thread waiting for libsymphonia that is now {status}`)

			continue
		end

		local resumed, resumeError = coroutine.resume(thread, succeeded, result)

		if not resumed then
			Sys.logger:warn(`a thread waiting for libsymphonia failed after the load resumed it: {resumeError}`)
		end
	end
end

--[=[
	@within Symphonia.Sys
	@private
	@yields

	Finds or downloads the library for this platform, opens it and checks its ABI version.
]=]
function Sys.openLibrary(): Lib
	if not stdPolyfills.runtime.capabilities().ffi then
		error("Symphonia requires FFI which is not available on this runtime", 0)
	end

	local types = stdPolyfills.ffi.getTypes()
	local void = types.void
	local i32 = types.i32
	local u32 = types.u32
	local pointer = types.pointer
	local platform = stdPolyfills.process.getPlatform()
	local rawArchitecture = stdPolyfills.process.getArch()
	local architecture = if rawArchitecture == "aarch64"
		then "arm64"
		elseif rawArchitecture == "x86" then "x86"
		else "x64"
	local result = binary.load({
		id = "libsymphonia",
		version = "0.0.2",
		url = "https://raw.githubusercontent.com/DiscordLuau/discord-luau/refs/tags/symphonia-{version}/packages/symphonia/binaries/{os}-{arch}/libsymphonia{ext}",
		checksum = CHECKSUMS[`{platform}-{architecture}`]
			or error(`Unsupported platform '{platform}-{architecture}' for libsymphonia`, 0),
	})
	local library = (
		stdPolyfills.ffi.dlopen(result.path, {
			symphonia_abi_version = { returns = i32, args = {} },
			symphonia_open_memory = { returns = pointer, args = { pointer, u32, pointer, pointer, u32 } },
			symphonia_open_file = { returns = pointer, args = { pointer, pointer, pointer, u32 } },
			symphonia_info = { returns = i32, args = { pointer, i32 } },
			symphonia_describe = { returns = i32, args = { pointer, i32, pointer, u32 } },
			symphonia_read = { returns = i32, args = { pointer, pointer, u32, pointer, u32 } },
			symphonia_read_packet = { returns = i32, args = { pointer, pointer, u32, pointer, u32 } },
			symphonia_open_stream = { returns = pointer, args = { pointer, u32 } },
			symphonia_push = { returns = i32, args = { pointer, pointer, u32 } },
			symphonia_finish = { returns = i32, args = { pointer } },
			symphonia_close = { returns = void, args = { pointer } },
			symphonia_open_count = { returns = i32, args = {} },
			symphonia_worker_count = { returns = i32, args = {} },
		}) :: any
	) :: Lib
	local abiVersion = library.symphonia_abi_version()

	if abiVersion ~= ABI_VERSION then
		error(`libsymphonia ABI version {abiVersion} does not match {ABI_VERSION}; update the symphonia package`, 0)
	end

	Sys.logger:debug(`loaded libsymphonia from {result.path}`)

	return library
end

export type Lib = {
	symphonia_abi_version: () -> number,
	symphonia_open_memory: (
		data: buffer,
		length: number,
		extension: buffer | FFIPointer,
		errorOut: FFIPointer,
		errorCapacity: number
	) -> FFIPointer,
	symphonia_open_file: (
		path: buffer,
		extension: buffer | FFIPointer,
		errorOut: FFIPointer,
		errorCapacity: number
	) -> FFIPointer,
	symphonia_info: (handle: FFIPointer, field: number) -> number,
	symphonia_describe: (handle: FFIPointer, field: number, out: FFIPointer, capacity: number) -> number,
	symphonia_read: (
		handle: FFIPointer,
		out: FFIPointer,
		capacityFrames: number,
		errorOut: FFIPointer,
		errorCapacity: number
	) -> number,
	symphonia_read_packet: (
		handle: FFIPointer,
		out: FFIPointer,
		capacity: number,
		errorOut: FFIPointer,
		errorCapacity: number
	) -> number,
	symphonia_open_stream: (errorOut: FFIPointer, errorCapacity: number) -> FFIPointer,
	symphonia_push: (handle: FFIPointer, data: buffer, length: number) -> number,
	symphonia_finish: (handle: FFIPointer) -> number,
	symphonia_close: (handle: FFIPointer) -> (),
	symphonia_open_count: () -> number,
	symphonia_worker_count: () -> number,
}

return Sys
