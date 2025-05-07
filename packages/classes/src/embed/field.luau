--[=[
	@class Classes.Field
	@__index Prototype

	Implementation of the Discord Field class in Luau. This class represents a field in a Discord embed, which can contain a name, value, and whether it should be displayed inline.

	https://discord.com/developers/docs/resources/message#embed-object-embed-field-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local Field = {}

Field.Interface = {}
Field.Prototype = {}

--[=[
	@within Classes.Field
	@private

	Responsible for syncing data to this field object. This is typically called by the API when this object is
	created or updated.
]=]
function Field.Prototype.sync(self: Field, fieldData: apiTypes.EmbedFieldObject)
	--[=[
		@prop name string
		@within Classes.Field
		The name of the field.
	]=]
	self.name = fieldData.name

	--[=[
		@prop value string
		@within Classes.Field
		The value of the field.
	]=]
	self.value = fieldData.value

	--[=[
		@prop inline boolean?
		@within Classes.Field
		Whether this field should be displayed inline with other fields.
	]=]
	self.inline = fieldData.inline
end

--[=[
	@within Classes.Field
	@private

	Responsible for constructing this class.
]=]
function Field.Interface.new(fieldData: apiTypes.EmbedFieldObject): Field
	local self = setmetatable({} :: Field, { __index = Field.Prototype })

	self:sync(fieldData)

	return self
end

export type Field = typeof(Field.Prototype) & {
	name: string,
	value: string,
	inline: boolean?,
}

return Field.Interface
