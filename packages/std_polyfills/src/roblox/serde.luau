-- selene: allow(undefined_variable)
local HttpService = game:GetService("HttpService")

local serde = {}

function serde.encode(format: string, value: any, _pretty: boolean?): string
	if format == "json" then
		return HttpService:JSONEncode(value)
	end

	error(`Unsupported serde format on Roblox: {format}`)
end

function serde.decode(format: string, encoded: string | buffer): any
	if format == "json" then
		local source = if type(encoded) == "buffer" then buffer.tostring(encoded) else encoded
		return HttpService:JSONDecode(source)
	end

	error(`Unsupported serde format on Roblox: {format}`)
end

function serde.compress(_format: string, _data: string | buffer, _level: number?): string
	error("serde.compress is not available on Roblox — disable gateway compression via capabilities().compress")
end

function serde.decompress(_format: string, _data: string | buffer): string
	error("serde.decompress is not available on Roblox — disable gateway compression via capabilities().compress")
end

return serde
