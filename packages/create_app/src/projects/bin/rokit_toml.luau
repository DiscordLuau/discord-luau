local StdPolyfills = require("../../../luau_packages/std_polyfills")

local RUNTIME_TOOLS = {
	zune = "Scythe-Technology/zune@0.5.5",
	lune = "lune-org/lune@0.10.4",
}

return function(runtime: string)
	return StdPolyfills.serde.encode("toml", {
		tools = {
			[runtime] = RUNTIME_TOOLS[runtime],
		},
	}, true)
end
