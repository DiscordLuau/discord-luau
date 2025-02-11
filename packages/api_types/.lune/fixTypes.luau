--> Task responsible for bundling the API-Types package, as well as fixing types for said package because at the moment
--> types are not bundled via Darklua.

local fs = require("@lune/fs")

local fileContent = fs.readFile("bundled.luau")
local response = fileContent:gsub("type%s+(%w+)__DARKLUA_TYPE_%w+", "export type %1"):gsub("__DARKLUA_TYPE_%w+", "")

fs.writeFile("bundled.luau", `--!nonstrict\n\n{response}`)
