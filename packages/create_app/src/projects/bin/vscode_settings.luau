local StdPolyfills = require("../../../lune_packages/std_polyfills")

return function()
	return StdPolyfills.serde.encode("json", {
		["editor.formatOnSave"] = true,
		["luau-lsp.inlayHints.variableTypes"] = true,
		["luau-lsp.inlayHints.functionReturnTypes"] = true,
		["luau-lsp.inlayHints.parameterNames"] = "all",
		["luau-lsp.inlayHints.parameterTypes"] = true,
		["luau-lsp.inlayHints.typeHintMaxLength"] = 50,
		["luau-lsp.fflags.override"] = {
			["LuauTarjanChildLimit"] = "0",
			["LuauTypeInferIterationLimit"] = "0",
		},
	}, true)
end
