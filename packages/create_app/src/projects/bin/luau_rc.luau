local StdPolyfills = require("../../../lune_packages/std_polyfills")

return function()
	return StdPolyfills.serde.encode("json", {
		aliases = {
			lune = "~/.lune/.typedefs/0.10.1/",
		},
	}, true)
end
