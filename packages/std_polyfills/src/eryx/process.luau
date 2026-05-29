local erxOs = require("@eryx/os")

local process = {}

-- os.arch() returns "x64"/"arm64"/"arm"/"x86" — map to the polyfill's expected output values
local archMap: { [string]: string } = {
	x64 = "x86_64",
	arm64 = "aarch64",
	arm = "aarch64",
	x86 = "x86_64",
}

process.os = (erxOs.platform() or "linux") :: "linux" | "macos" | "windows"
process.arch = (archMap[erxOs.arch() or "x64"] or "x86_64") :: "x86_64" | "aarch64"

-- Strip the script path (first element) to match Lune/Zune convention
local rawArgs = erxOs.cliargs()
process.args = table.move(rawArgs, 2, #rawArgs, 1, {})

process.env = erxOs.environ()

process.cwd = tostring(erxOs.cwd())

function process.run(exec: string, args: { string }?, opts: any?)
	local result = erxOs.exec(exec, args or {}, opts)

	return {
		ok = result.code == 0,
		code = result.code,
		stdout = result.stdout,
		stderr = result.stderr,
	}
end

return process
