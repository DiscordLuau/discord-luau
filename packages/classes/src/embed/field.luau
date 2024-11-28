--[[
	Implementation of the Discord Field class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-field-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local Field = {}

Field.Interface = {}
Field.Prototype = {}

function Field.Prototype.sync(self: Field, fieldData: apiTypes.EmbedFieldObject)
	self.name = fieldData.name
	self.value = fieldData.value
	self.inline = fieldData.inline
end

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
