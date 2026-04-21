local pesde_future_patch = require("./bin/pesde_future_patch")
local vscode_settings = require("./bin/vscode_settings")
local license_md = require("./bin/license_md")
local init_src = require("./bin/init_src")
local env_file = require("./bin/env_file")
local luau_rc = require("./bin/luau_rc")
local pesde_toml = require("./bin/pesde_toml")
local rokit_toml = require("./bin/rokit_toml")
local selene_toml = require("./bin/selene_toml")
local git_attributes = require("./bin/git_attributes")
local gitignore = require("./bin/gitignore")

type Information = {
	ProjectName: string,
	IDE: string,
	UseGit: string,
	License: string,
	DiscordToken: string,
}

return {
	[".vscode"] = {
		["settings.json"] = function(_information: Information)
			return vscode_settings()
		end,
	},
	["patches"] = {
		["yetanotherclown+luau_futures-2.0.0-beta.3+luau.patch"] = function(_information: Information)
			return pesde_future_patch()
		end,
	},
	["src"] = {
		["init.luau"] = function(_information: Information)
			return init_src()
		end,
	},
	[".env.luau"] = function(information: Information)
		return env_file(information.DiscordToken)
	end,
	[".gitattributes"] = function(_information: Information)
		return git_attributes()
	end,
	[".gitignore"] = function(_information: Information)
		return gitignore()
	end,
	[".luaurc"] = function(_information: Information)
		return luau_rc()
	end,
	["pesde.toml"] = function(information: Information)
		return pesde_toml(information.ProjectName, information.License)
	end,
	["rokit.toml"] = function(_information: Information)
		return rokit_toml()
	end,
	["selene.toml"] = function(_information: Information)
		return selene_toml()
	end,
	["LICENSE.md"] = function(information: Information)
		return license_md(information.License, information.ProjectName)
	end,
}
