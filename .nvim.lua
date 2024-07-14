require("luau-lsp").config({
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
					directoryAliases = {
						["@lune"] = "~/.lune/.typedefs/0.8.6/",
						["@builders"] = "./packages/builders",
						["@cdn"] = "./packages/cdn/src",
						["@classes"] = "./packages/classes/src",
						["@core"] = "./packages/core/src",
						["@extensions"] = "./packages/extensions/src",
						["@std-polyfills"] = "./packages/std-polyfills/src",
						["@api-types"] = "./packages/api-types/src",
						["@utils"] = "./packages/utils/src",
						["@vendor"] = "./packages/vendor/src",
						["@voice"] = "./packages/voice/src",
						["@websocket"] = "./packages/voice/src",
					},
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
