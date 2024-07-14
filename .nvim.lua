require("luau-lsp").config {
    server = {
        settings = {
            ["luau-lsp"] = {
                inlayHints = {
                    variableTypes = true,
                    parameterNames = "all",
                    typeHintMaxLength = 20,
                },
                require = {
                    mode = "relativeToFile",
                    directoryAliases = {
                        ["@lune"] = "~/.lune/.typedefs/0.8.6/",
                        ["@vendor"] = "./vendor",
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
}
