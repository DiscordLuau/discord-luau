--[=[
	@class Types.user
]=]

local util = require("../lune_packages/util")

local NitroType = table.freeze(util.tableReflect({
	None = 0,
	NitroClassic = 1,
	Nitro = 2,
	NitroBasic = 3,
}))

export type NitroType = "None" | "NitroClassic" | "Nitro" | "NitroBasic"

return {
	NitroType = NitroType,
}
