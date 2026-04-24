local StdPolyfills = require("../../../luau_packages/std_polyfills")

return function()
	return StdPolyfills.serde.encode("json", {
		lsp = {
			["luau-lsp"] = {
				settings = {
					["luau-lsp"] = {
						inlayHints = {
							variableTypes = true,
							functionReturnTypes = true,
							parameterNames = "all",
							parameterTypes = true,
							typeHintMaxLength = 50,
						},
						fflags = {
							override = {
								LuauTarjanChildLimit = "0",
								LuauTypeInferIterationLimit = "0",
							},
						},
					},
				},
			},
		},
	}, true)
end
