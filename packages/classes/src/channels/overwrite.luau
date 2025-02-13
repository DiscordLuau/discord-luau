--[[
	Implementation of the Discord Overwrite class in Luau

	https://discord.com/developers/docs/resources/channel#overwrite-object
]]

local apiTypes = require("../../lune_packages/api_types")

local Overwrite = {}

Overwrite.Interface = {}
Overwrite.Prototype = {}

function Overwrite.Prototype.sync(self: Overwrite, overwriteData: apiTypes.OverwriteObject)
	self.type = (overwriteData.type == 0 and "role" or "member") :: OverwriteType

	self.id = overwriteData.id
	self.allow = overwriteData.allow
	self.deny = overwriteData.deny
end

function Overwrite.Interface.new(overwriteData: apiTypes.OverwriteObject): Overwrite
	local self = setmetatable({} :: Overwrite, { __index = Overwrite.Prototype })

	self:sync(overwriteData)

	return self
end

export type OverwriteType = "role" | "member"
export type Overwrite = typeof(Overwrite.Prototype) & {
	id: apiTypes.Snowflake,
	type: OverwriteType,
	allow: string,
	deny: string,
}

return Overwrite.Interface
