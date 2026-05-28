-- selene: allow(undefined_variable)
local process = {}

-- Roblox does not expose OS/env/args/cwd; return safe stubs so callers
-- that only read these for informational purposes don't crash.
process.os = "windows" :: "windows" | "linux" | "macos"
process.args = {} :: { string }
process.env = {} :: { [string]: string }
process.cwd = "" :: string

return process
