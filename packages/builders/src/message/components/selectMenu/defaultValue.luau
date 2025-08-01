--[=[
	@class Builders.DefaultValue
	@__index Prototype

	Implementation of discords DefaultValue object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-default-value-structure
]=]

local apiTypes = require("../../../../lune_packages/api_types")

local DefaultValue = {}

DefaultValue.Prototype = {}
DefaultValue.Interface = {}

--[=[
	@within Builders.DefaultValue

	Sets the id of the default value.
]=]
function DefaultValue.Prototype.setId(self: DefaultValue, id: string): DefaultValue
	self.id = id

	return self
end

--[=[
	@within Builders.DefaultValue

	Sets the type of the default value.
]=]
function DefaultValue.Prototype.setType(self: DefaultValue, type: apiTypes.SelectDefaultValueType): DefaultValue
	self.type = type

	return self
end

--[=[
	@within Builders.DefaultValue

	Responsible for building the DefaultValue JSON that can be parsed by the Discord API.
]=]
function DefaultValue.Prototype.build(self: DefaultValue): JSON
	assert(self.id, `DefaultValue id is required`)
	assert(self.type, `DefaultValue type is required`)

	return {
		id = self.id,
		type = self.type,
	}
end

--[=[
	@within Builders.DefaultValue

	Responsible for creating a new DefaultValue.

	```luau
	local defaultValue = DefaultValue.new({
		id = "123",
		type = "user"
	})
	```
]=]
function DefaultValue.Interface.new(resource: {
	id: string,
	type: apiTypes.SelectDefaultValueType,
}?): DefaultValue
	local self = setmetatable(
		{
			--[=[
				@prop id string
				@within Builders.DefaultValue
				The id of the default value.
			]=]
			id = nil,

			--[=[
				@prop type apiTypes.SelectDefaultValueType
				@within Builders.DefaultValue
				The type of the default value.
			]=]
			type = nil,
		} :: DefaultValue,
		{
			__index = DefaultValue.Prototype,
		}
	)

	if resource then
		if resource.id then
			self:setId(resource.id)
		end

		if resource.type then
			self:setType(resource.type)
		end
	end

	return self
end

export type DefaultValue = typeof(DefaultValue.Prototype) & {
	id: string,
	type: apiTypes.SelectDefaultValueType,
}

export type JSON = typeof(DefaultValue.Prototype.build(nil :: any))

return DefaultValue.Interface
