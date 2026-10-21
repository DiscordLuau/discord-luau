local StdPolyfills = require("../../../luau_packages/std_polyfills")

local RUNTIME_ALIASES = {
	lune = { lune = "~/.lune/.typedefs/0.11.0/" },
	zune = { zune = "~/.zune/typedefs/" },
	lute = { lute = "~/.lute/typedefs/1.0.1/lute/", std = "~/.lute/typedefs/1.0.1/std/" },
}

return function(runtime: string)
	return StdPolyfills.serde.encode("json", {
		aliases = RUNTIME_ALIASES[runtime] or RUNTIME_ALIASES.lune,
	}, true)
end
