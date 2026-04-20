local StdPolyfills = require("../../../lune_packages/std_polyfills")

return function()
	return StdPolyfills.serde.encode("toml", {
		tools = {
			lune = "lune-org/lune@0.10.1",
		},
	}, true)
end
