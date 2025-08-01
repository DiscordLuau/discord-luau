require("@self/luau-lsp").config({
	server = {
		settings = {
			["luau-lsp"] = {
				inlayHints = {
					variableTypes = true,
					functionReturnTypes = true,
					parameterNames = "all",
					typeHintMaxLength = 20,
				},
				require = {
					mode = "relativeToFile",
					directoryAliases = {},
				},
				completion = {
					imports = {
						enabled = true,
					},
				},
			},
		},
	},
	platform = {
		type = "standard",
	},
})
