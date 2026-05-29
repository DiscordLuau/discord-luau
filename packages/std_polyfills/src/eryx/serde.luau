local brotli = require("@eryx/compression/brotli")
local gzip = require("@eryx/compression/gzip")
local zlib = require("@eryx/compression/zlib")
local json = require("@eryx/data/json")
local toml = require("@eryx/data/toml")
local yaml = require("@eryx/data/yaml")

local serde = {}

local function toBuffer(data: string | buffer): buffer
	return if type(data) == "buffer" then data :: buffer else buffer.fromstring(data :: string)
end

function serde.encode(format: string, value: any, pretty: boolean?): string
	if format == "json" then
		return json.encode(value, if pretty then { pretty = true } else nil)
	elseif format == "yaml" then
		return yaml.encode(value)
	elseif format == "toml" then
		return toml.encode(value)
	end

	error(`Unsupported serde format: {format}`)
end

function serde.decode(format: string, encoded: string | buffer): any
	local source: string = if type(encoded) == "buffer" then buffer.tostring(encoded) else encoded :: string

	if format == "json" then
		return json.decode(source)
	elseif format == "yaml" then
		return yaml.decode(source)
	elseif format == "toml" then
		return toml.decode(source)
	end

	error(`Unsupported serde format: {format}`)
end

function serde.compress(format: string, data: string | buffer, _level: number?): string
	local input = toBuffer(data)

	if format == "zlib" then
		return buffer.tostring(zlib.compress(input))
	elseif format == "gzip" then
		return buffer.tostring(gzip.compress(input))
	elseif format == "brotli" then
		return buffer.tostring(brotli.compress(input))
	end

	error(`Unsupported compression format: {format}`)
end

function serde.decompress(format: string, data: string | buffer): string
	local input = toBuffer(data)

	if format == "zlib" then
		return buffer.tostring(zlib.decompress(input))
	elseif format == "gzip" then
		return buffer.tostring(gzip.decompress(input))
	elseif format == "brotli" then
		return buffer.tostring(brotli.decompress(input))
	end

	error(`Unsupported decompression format: {format}`)
end

return serde
