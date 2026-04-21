-- selene: allow(undefined_variable)
local zuneSerde = zune.serde

local serde = {}

function serde.encode(format: string, value: any, pretty: boolean?): string
	if format == "json" then
		local config = if pretty then { pretty_indent = zuneSerde.json.indents.four_spaces } else nil
		return zuneSerde.json.encode(value, config)
	elseif format == "yaml" then
		return zuneSerde.yaml.encode(value)
	elseif format == "toml" then
		return zuneSerde.toml.encode(value)
	end

	error(`Unsupported serde format: {format}`)
end

function serde.decode(format: string, encoded: string | buffer): any
	if format == "json" then
		return zuneSerde.json.decode(encoded :: string)
	elseif format == "yaml" then
		return zuneSerde.yaml.decode(encoded)
	elseif format == "toml" then
		return zuneSerde.toml.decode(encoded)
	end

	error(`Unsupported serde format: {format}`)
end

function serde.compress(format: string, s: string | buffer, level: number?): string
	local opts = if level then { level = level } else nil

	if format == "gzip" then
		return zuneSerde.gzip.compress(s, opts) :: string
	elseif format == "brotli" then
		return zuneSerde.brotli.compress(s, opts) :: string
	elseif format == "lz4" then
		return zuneSerde.lz4.compressFrame(s, opts) :: string
	elseif format == "zlib" then
		return zuneSerde.zlib.compress(s, opts) :: string
	end

	error(`Unsupported compression format: {format}`)
end

function serde.decompress(format: string, s: string | buffer): string
	if format == "gzip" then
		return zuneSerde.gzip.decompress(s) :: string
	elseif format == "brotli" then
		return zuneSerde.brotli.decompress(s) :: string
	elseif format == "lz4" then
		return zuneSerde.lz4.decompressFrame(s) :: string
	elseif format == "zlib" then
		return zuneSerde.zlib.decompress(s) :: string
	end

	error(`Unsupported decompression format: {format}`)
end

return serde
