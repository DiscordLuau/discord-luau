local reflect = require("@utils/table/reflect")

local NitroType = table.freeze(reflect({
	None = 0,
	NitroClassic = 1,
	Nitro = 2,
	NitroBasic = 3,
}))

export type NitroType = "None" | "NitroClassic" | "Nitro" | "NitroBasic"

return {
	NitroType = NitroType,
}
