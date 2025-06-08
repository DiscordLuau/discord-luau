--[=[
	@class StdPolyfills.serde
]=]

local runtime = require("@self/runtime")

local serde = {}

--[=[
	@within StdPolyfills.serde

	Encodes the given value using the given format.
]=]
function serde.encode(format: EncodeDecodeFormat, value: any, pretty: boolean?): string
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/serde").encode(format, value, pretty)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.serde

	Decodes the given string using the given format into a lua value.
]=]
function serde.decode(format: EncodeDecodeFormat, encoded: buffer | string): any
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/serde").decode(format, encoded)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.serde

	Decompresses the given string using the given format.
]=]
function serde.decompress(format: CompressDecompressFormat, s: buffer | string): string
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/serde").decompress(format, s)
	end

	error(`Out of reach`)
end

--[=[
	@within StdPolyfills.serde

	Compresses the given string using the given format.
]=]
function serde.compress(format: CompressDecompressFormat, s: buffer | string, level: number?): string
	local target = runtime.assertRuntime()

	if target == "Lune" then
		return require("./lune/serde").compress(format, s, level)
	end

	error(`Out of reach`)
end

export type EncodeDecodeFormat = "json" | "yaml" | "toml"
export type CompressDecompressFormat = "brotli" | "gzip" | "lz4" | "zlib"

return serde
