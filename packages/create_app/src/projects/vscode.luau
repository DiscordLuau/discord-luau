local StdPolyfills = require("../../lune_packages/std_polyfills")

local pesde_future_patch = require("./bin/pesde_future_patch")
local vscode_settings = require("./bin/vscode_settings")
local init_src = require("./bin/init_src")
local env_file = require("./bin/env_file")
local luau_rc = require("./bin/luau_rc")
local pesde_toml = require("./bin/pesde_toml")
local rokit_toml = require("./bin/rokit_toml")
local git_attributes = require("./bin/git_attributes")

type Information = {
	ProjectName: string,
	UseGit: string,
	License: string,
	DiscordToken: string,
}

return {
	[".vscode"] = {
		["settings.json"] = function(information: Information)
			return vscode_settings()
		end,
	},
	["patches"] = {
		["yetanotherclown+luau_futures-2.0.0-beta.3+luau.patch"] = function(information: Information)
			return pesde_future_patch()
		end,
	},
	["src"] = {
		["init.luau"] = function(information: Information)
			return init_src()
		end,
	},
	[".env.luau"] = function(information: Information)
		return env_file(information.DiscordToken)
	end,
	[".gitattributes"] = function(information: Information)
		return git_attributes()
	end,
	[".luaurc"] = function(information: Information)
		return luau_rc()
	end,
	["pesde.toml"] = function(information: Information)
		return pesde_toml(information.ProjectName, information.License)
	end,
	["rokit.toml"] = function(information: Information)
		return rokit_toml()
	end,
}
