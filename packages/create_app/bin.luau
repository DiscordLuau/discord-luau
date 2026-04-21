local process = require("@lune/process")

local scriptSource: string = debug.info(1, "s")
local packageDirectory: string = string.match(scriptSource, "^(.*)[/\\][^/\\]+$") or "."

local entryPoint = packageDirectory .. "/src/init.luau"
local osInfo = process.os

local spawnArgs: { string } = { "run", entryPoint }

for _, argument in process.args do
	table.insert(spawnArgs, argument)
end

if osInfo == "windows" then
	process.exec("cmd", { "/c", "start", "/wait", "zune", table.unpack(spawnArgs) }, {
		stdio = "forward",
	})
else
	local commandString = "zune " .. table.concat(spawnArgs, " ") .. " < /dev/tty > /dev/tty"

	process.exec("sh", { "-c", commandString }, {
		stdio = "forward",
	})
end
