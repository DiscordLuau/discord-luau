local json = require("@eryx/data/json")
local zlib = require("@eryx/compression/zlib")

local serde = {}

function serde.encode(format: string, value: any, pretty: boolean?): string
	if format == "json" then
		return json.encode(value, if pretty then { pretty = true } else nil)
	elseif format == "yaml" then
		return require("@eryx/data/yaml").encode(value)
	elseif format == "toml" then
		return require("@eryx/data/toml").encode(value)
	end
	error(`Unsupported serde format: {format}`)
end

function serde.decode(format: string, encoded: string | buffer): any
	local str: string = if type(encoded) == "buffer" then buffer.tostring(encoded) else encoded :: string
	if format == "json" then
		return json.decode(str)
	elseif format == "yaml" then
		return require("@eryx/data/yaml").decode(str)
	elseif format == "toml" then
		return require("@eryx/data/toml").decode(str)
	end
	error(`Unsupported serde format: {format}`)
end

-- All @eryx/compression modules require buffer input and return buffer output.
local function toBuf(s: string | buffer): buffer
	return if type(s) == "buffer" then s :: buffer else buffer.fromstring(s :: string)
end

function serde.compress(format: string, s: string | buffer, _level: number?): string
	local data = toBuf(s)
	if format == "zlib" then
		return buffer.tostring(zlib.compress(data))
	elseif format == "gzip" then
		return buffer.tostring(require("@eryx/compression/gzip").compress(data))
	elseif format == "brotli" then
		return buffer.tostring(require("@eryx/compression/brotli").compress(data))
	end
	error(`Unsupported compression format: {format}`)
end

function serde.decompress(format: string, s: string | buffer): string
	local data = toBuf(s)
	if format == "zlib" then
		return buffer.tostring(zlib.decompress(data))
	elseif format == "gzip" then
		return buffer.tostring(require("@eryx/compression/gzip").decompress(data))
	elseif format == "brotli" then
		return buffer.tostring(require("@eryx/compression/brotli").decompress(data))
	end
	error(`Unsupported decompression format: {format}`)
end

return serde
