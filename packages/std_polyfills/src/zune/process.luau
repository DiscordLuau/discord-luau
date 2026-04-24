-- selene: allow(undefined_variable)
local process = {}

process.os = zune.platform.os
-- Zune includes the script path as args[1]; strip it to match Lune's convention
local rawArgs = zune.process.args
process.args = table.move(rawArgs, 2, #rawArgs, 1, {})
process.env = zune.process.env
process.cwd = zune.process.cwd()

function process.run(exec: string, args: { string }?, opts: { cwd: string?, env: { [string]: string }? }?)
	return zune.process.run(exec, args, opts)
end

return process
