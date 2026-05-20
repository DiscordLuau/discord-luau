local StdPolyfills = require("../../../luau_packages/std_polyfills")

return function(runtime: string)
	local settings: { [string]: any } = {
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
	}

	if string.lower(runtime) == "zune" then
		local platform = StdPolyfills.process.getPlatform()
		local homeVar = if platform == "windows" then "USERPROFILE" else "HOME"
		local home = StdPolyfills.process.getEnv()[homeVar] or "~"

		settings["luau-lsp.types.definitionFiles"] = {
			["@zune"] = `{home}/.zune/typedefs/global/zune.d.luau`,
		}
		settings["luau-lsp.types.documentationFiles"] = {
			`{home}/.zune/typedefs/global/zune.d.json`,
		}
	end

	return StdPolyfills.serde.encode("json", settings, true)
end
