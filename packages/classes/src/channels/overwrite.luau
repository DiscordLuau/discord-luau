--[=[
	@class Classes.Overwrite
	@__index Prototype

	Implementation of the Discord Overwrite class in Luau

	https://discord.com/developers/docs/resources/channel#overwrite-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local Overwrite = {}

Overwrite.Interface = {}
Overwrite.Prototype = {}

--[=[
	@within Classes.Overwrite
	@private

	Responsible for syncing data to this overwrite object. This is typically called by the API when this object is
	created or updated.
]=]
function Overwrite.Prototype.sync(self: Overwrite, overwriteData: apiTypes.OverwriteObject)
	--[=[
		@prop type OverwriteType
		@within Classes.Overwrite

		The type of overwrite. Can be either "role" or "member" depending on whether this overwrite 
		applies to a role or a specific member.
	]=]
	self.type = (overwriteData.type == 0 and "role" or "member") :: OverwriteType

	--[=[
		@prop id string
		@within Classes.Overwrite

		The role or user ID for this overwrite.
	]=]
	self.id = overwriteData.id

	--[=[
		@prop allow string
		@within Classes.Overwrite

		The permissions that are explicitly allowed for this overwrite.
	]=]
	self.allow = overwriteData.allow

	--[=[
		@prop deny string
		@within Classes.Overwrite

		The permissions that are explicitly denied for this overwrite.
	]=]
	self.deny = overwriteData.deny
end

--[=[
	@within Classes.Overwrite
	@private

	Responsible for constructing this class.
]=]
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
