--[=[
	@class Builders.Field
	@__index Prototype

	Implementation of discords Field object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#embed-object-embed-field-structure
]=]

local Field = {}

Field.Prototype = {}
Field.Interface = {}

--[=[
	@within Builders.Field

	Set the name of the field
]=]
function Field.Prototype.setName(self: Field, name: string): Field
	assert(#name <= 256, "Name must be less than 256 characters")
	assert(#name > 1, "Name must be greater than 1 characters")

	self.name = name

	return self
end

--[=[
	@within Builders.Field

	Set the value of the field
]=]
function Field.Prototype.setValue(self: Field, value: string): Field
	self.value = value

	return self
end

--[=[
	@within Builders.Field

	Set if the field is inline.
]=]
function Field.Prototype.setIsInline(self: Field, isInline: boolean): Field
	self.inline = isInline

	return self
end

--[=[
	@within Builders.Field

	Responsible for building the Field JSON that can be parsed by the Discord API.
]=]
function Field.Prototype.build(self: Field): JSON
	assert(self.name, `Field must have a name`)
	assert(self.value, `Field must have a value`)

	return {
		name = self.name,
		value = self.value,
		inline = self.inline,
	}
end

--[=[
	@within Builders.Field

	Responsible for creating a new Field.
]=]
function Field.Interface.new(resource: {
	name: string?,
	value: string?,
	inline: boolean?,
}?): Field
	local self = setmetatable(
		{
			--[=[
				@prop name string?
				@within Builders.Field
				The name of the field that is displayed.
			]=]
			name = nil,

			--[=[
				@prop value string?
				@within Builders.Field
				The value of the field that is displayed.
			]=]
			value = nil,

			--[=[
				@prop inline boolean?
				@within Builders.Field
				Whether or not this field should display inline.
			]=]
			inline = nil,
		} :: Field,
		{
			__index = Field.Prototype,
		}
	)

	if resource then
		if resource.name then
			self:setName(resource.name)
		end

		if resource.value then
			self:setValue(resource.value)
		end

		if resource.inline then
			self:setIsInline(resource.inline)
		end
	end

	return self
end

export type Field = typeof(Field.Prototype) & {
	name: string?,
	value: string?,
	inline: boolean?,
}

export type JSON = typeof(Field.Prototype.build({} :: any))

return Field.Interface
