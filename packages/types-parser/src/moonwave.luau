local Process = require("@std-polyfills/process")
local Serde = require("@std-polyfills/serde")

local MoonwaveTypes = require("@types/moonwaveTypes")

local Moonwave = {}

function Moonwave.extractCommentsIntoJson(path: string): MoonwaveTypes.MoonwaveDataExportArray
	local moonwaveExtractResult = Process.spawn("moonwave", {
		"extract",
		path,
	})

	if not moonwaveExtractResult.ok then
		error(moonwaveExtractResult.stderr)
	else
		local moonwaveData = Serde.decode("json", moonwaveExtractResult.stdout)

		return moonwaveData
	end
end

return Moonwave
