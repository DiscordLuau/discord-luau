--[[
	Implementation of the Discord InstallParams class in Luau

	https://discord.com/developers/docs/resources/application#install-params-object
]]

local apiTypes = require("../../lune_packages/api_types")

local permission = require("../permission")

local InstallParams = {}

InstallParams.Interface = {}
InstallParams.Prototype = {}

function InstallParams.Prototype.sync(self: InstallParams, installParamsData: apiTypes.InstallParamsObject)
	self.scopes = installParamsData.scopes
	self.permissions = permission.new(installParamsData.permissions)
end

function InstallParams.Interface.new(installParamsData: apiTypes.InstallParamsObject): InstallParams
	local self = setmetatable({} :: InstallParams, { __index = InstallParams.Prototype })

	self:sync(installParamsData)

	return self
end

export type InstallParams = typeof(InstallParams.Prototype) & {
	scopes: { apiTypes.OAuth2Scopes },
	permissions: permission.Permission,
}

return InstallParams.Interface
