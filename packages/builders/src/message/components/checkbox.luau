--[=[
	@class Builders.Message.Checkbox
	@__index Prototype

	Implementation of Discord's Checkbox component as a Luau builder.
	Single checkbox for a yes/no choice. Modal-only when using the required field.

	https://docs.discord.com/developers/components/reference#checkbox
]=]

--[=[
	@prop customId string?
	@within Builders.Message.Checkbox
	Developer-defined identifier; 1-100 characters.
]=]

--[=[
	@prop required boolean?
	@within Builders.Message.Checkbox
	Whether required in modal (defaults to true).
]=]

--[=[
	@prop default boolean?
	@within Builders.Message.Checkbox
	Whether checked by default (defaults to false).
]=]

local apiTypes = require("../../../luau_packages/api_types")

local Checkbox = {}

Checkbox.Prototype = {}
Checkbox.Interface = {}

--[=[
	@within Builders.Message.Checkbox

	Sets the developer-defined identifier. 1-100 characters.
]=]
function Checkbox.Prototype.setCustomId(self: Checkbox, customId: string): Checkbox
	assert(#customId >= 1, "customId must be at least 1 character")
	assert(#customId <= 100, "customId must be at most 100 characters")

	self.customId = customId

	return self
end

--[=[
	@within Builders.Message.Checkbox

	Sets whether this component is required in a modal.
]=]
function Checkbox.Prototype.setRequired(self: Checkbox, required: boolean): Checkbox
	self.required = required

	return self
end

--[=[
	@within Builders.Message.Checkbox

	Sets whether the checkbox is checked by default.
]=]
function Checkbox.Prototype.setDefault(self: Checkbox, default: boolean): Checkbox
	self.default = default

	return self
end

--[=[
	@within Builders.Message.Checkbox

	Responsible for building the Checkbox JSON that can be parsed by the Discord API.
]=]
function Checkbox.Prototype.build(self: Checkbox): JSON
	assert(self.customId, "Checkbox.customId is required")

	return {
		type = 23,
		custom_id = self.customId,
		required = self.required,
		default = self.default,
	}
end

--[=[
	@within Builders.Message.Checkbox

	Responsible for creating a new Checkbox.
]=]
function Checkbox.Interface.new(resource: {
	customId: string?,
	required: boolean?,
	default: boolean?,
}?): Checkbox
	local self = setmetatable(
		{
			customId = nil,
			required = nil,
			default = nil,
		} :: Checkbox,
		{
			__index = Checkbox.Prototype,
		}
	)

	if resource then
		if resource.customId then
			self:setCustomId(resource.customId)
		end

		if resource.required ~= nil then
			self:setRequired(resource.required)
		end

		if resource.default ~= nil then
			self:setDefault(resource.default)
		end
	end

	return self
end

export type Checkbox = typeof(Checkbox.Prototype) & {
	customId: string?,
	required: boolean?,
	default: boolean?,
}

export type JSON = apiTypes.CheckboxComponentObject

return Checkbox.Interface
