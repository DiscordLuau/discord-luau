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
discord = { repo = "https://github.com/DiscordLuau/discord-luau.git", rev = "3f6eb77", path = "packages/discord_luau" }
builders = { repo = "https://github.com/DiscordLuau/discord-luau.git", rev = "3f6eb77", path = "packages/builders" }
classes = { repo = "https://github.com/DiscordLuau/discord-luau.git", rev = "3f6eb77", path = "packages/classes" }

[patches]
"yetanotherclown/luau_futures" = { "2.0.0-beta.3 luau" = "patches/yetanotherclown+luau_futures-2.0.0-beta.3+luau.patch" }
"kimpure/sha256" = { "0.1.1 luau" = "patches/kimpure+sha256-0.1.1.patch" }
]]
end
