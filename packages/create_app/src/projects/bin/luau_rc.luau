local StdPolyfills = require("../../../luau_packages/std_polyfills")

local RUNTIME_ALIASES = {
	lune = { lune = "~/.lune/.typedefs/0.10.1/" },
	zune = { zune = "~/.zune/typedefs/" },
}

return function(runtime: string)
	return StdPolyfills.serde.encode("json", {
		aliases = RUNTIME_ALIASES[runtime] or RUNTIME_ALIASES.lune,
	}, true)
end
