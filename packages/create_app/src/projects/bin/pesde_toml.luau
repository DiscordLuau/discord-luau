return function(projectName: string, license: string)
	local safeName = string.lower(string.gsub(projectName, "%-", "_") :: string)

	return [[name = "]]
		.. safeName
		.. [["
version = "0.1.0"
license = "]]
		.. license
		.. [["
pesde_version = "0.7.1"

[target]
environment = "luau"

[indices]
default = "https://github.com/pesde-pkg/index"

[dependencies]
discord = { name = "discord_luau/discord_luau", version = "0.0.5" }
builders = { name = "discord_luau/builders", version = "0.0.4" }
classes = { name = "discord_luau/classes", version = "0.0.6" }

[patches]
"yetanotherclown/luau_futures" = { "2.0.0-beta.3 luau" = "patches/yetanotherclown+luau_futures-2.0.0-beta.3+luau.patch" }
"kimpure/sha256" = { "0.1.1 luau" = "patches/kimpure+sha256-0.1.1.patch" }
]]
end
