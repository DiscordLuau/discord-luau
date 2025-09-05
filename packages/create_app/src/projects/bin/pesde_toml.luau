local StdPolyfills = require("../../../lune_packages/std_polyfills")

return function(projectName: string, license: string)
	return [[name = "]]
		.. projectName
		.. [["
version = "0.1.0"
license = "]]
		.. license
		.. [["

[target]
environment = "lune"

[indices]
default = "https://github.com/pesde-pkg/index"

[dependencies]
discord = { repo = "https://github.com/DiscordLuau/discord-luau.git", rev = "68e98df", path = "packages/discord_luau" }
builders = { repo = "https://github.com/DiscordLuau/discord-luau.git", rev = "68e98df", path = "packages/builders" }
classes = { repo = "https://github.com/DiscordLuau/discord-luau.git", rev = "68e98df", path = "packages/classes" }

[patches]
"yetanotherclown/luau_futures" = { "2.0.0-beta.3 luau" = "patches/yetanotherclown+luau_futures-2.0.0-beta.3+luau.patch" }
]]
end
