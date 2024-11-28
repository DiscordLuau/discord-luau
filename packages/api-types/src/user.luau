local utilitues = require("../lune_packages/utilities")

local NitroType = table.freeze(utilitues.table.reflect({
	None = 0,
	NitroClassic = 1,
	Nitro = 2,
	NitroBasic = 3,
}))

export type NitroType = "None" | "NitroClassic" | "Nitro" | "NitroBasic"

return {
	NitroType = NitroType,
}
