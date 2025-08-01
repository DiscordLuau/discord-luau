--[=[
	@class Classes.InstallParams
	@__index Prototype

	Implementation of the Discord InstallParams class in Luau

	https://discord.com/developers/docs/resources/application#install-params-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local permission = require("../permission")

local InstallParams = {}

InstallParams.Interface = {}
InstallParams.Prototype = {}

--[=[
	@within Classes.InstallParams
	@private

	Responsible for syncing data to this install params object. This is typically called by the API when this object is
	created or updated.
]=]
function InstallParams.Prototype.sync(self: InstallParams, installParamsData: apiTypes.InstallParamsObject)
	--[=[
		@prop scopes { apiTypes.OAuth2Scopes }
		@within Classes.InstallParams
	]=]
	self.scopes = installParamsData.scopes

	--[=[
		@prop permissions Classes.Permission
		@within Classes.InstallParams
	]=]
	self.permissions = permission.new(installParamsData.permissions)
end

--[=[
	@within Classes.InstallParams
	@private

	Responsible for constructing this class.
]=]
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
