--[=[
	@class Builders.Message.Label
	@__index Prototype

	Implementation of Discord's Label component as a Luau builder.
	Labels associate a label and description with a single interactive component.
	Recommended over ActionRow in modals.

	https://docs.discord.com/developers/components/reference#label
]=]

--[=[
	@prop label string?
	@within Builders.Message.Label
	The label text; max 45 characters.
]=]

--[=[
	@prop description string?
	@within Builders.Message.Label
	Additional description text; max 100 characters.
]=]

--[=[
	@prop component any?
	@within Builders.Message.Label
	A component to associate with the label.
]=]

--[=[
	@prop required boolean?
	@within Builders.Message.Label
	Whether this component is required (defaults to true).
]=]

local apiTypes = require("../../../luau_packages/api_types")

local Label = {}

Label.Prototype = {}
Label.Interface = {}

--[=[
	@within Builders.Message.Label

	Sets the label text. Max 45 characters.
]=]
function Label.Prototype.setLabel(self: Label, label: string): Label
	assert(#label >= 1, "label must be at least 1 character")
	assert(#label <= 45, "label must be at most 45 characters")

	self.label = label

	return self
end

--[=[
	@within Builders.Message.Label

	Sets the description text. Max 100 characters.
]=]
function Label.Prototype.setDescription(self: Label, description: string): Label
	assert(#description <= 100, "description must be at most 100 characters")

	self.description = description

	return self
end

--[=[
	@within Builders.Message.Label

	Sets the interactive component to associate with this label.
]=]
function Label.Prototype.setComponent(self: Label, component: apiTypes.ComponentObjects): Label
	self.component = component

	return self
end

--[=[
	@within Builders.Message.Label

	Sets whether this component is required in a modal.
]=]
function Label.Prototype.setRequired(self: Label, required: boolean): Label
	self.required = required

	return self
end

--[=[
	@within Builders.Message.Label

	Responsible for building the Label JSON that can be parsed by the Discord API.
]=]
function Label.Prototype.build(self: Label): JSON
	assert(self.label, "Label.label is required")
	assert(self.component, "Label.component is required")

	return {
		type = 18,
		label = self.label,
		description = self.description,
		component = self.component,
		required = self.required,
	}
end

--[=[
	@within Builders.Message.Label

	Responsible for creating a new Label.
]=]
function Label.Interface.new(resource: {
	label: string?,
	description: string?,
	component: apiTypes.ComponentObjects?,
	required: boolean?,
}?): Label
	local self = setmetatable(
		{
			label = nil,
			description = nil,
			component = nil,
			required = nil,
		} :: Label,
		{
			__index = Label.Prototype,
		}
	)

	if resource then
		if resource.label then
			self:setLabel(resource.label)
		end

		if resource.description then
			self:setDescription(resource.description)
		end

		if resource.component then
			self:setComponent(resource.component)
		end

		if resource.required ~= nil then
			self:setRequired(resource.required)
		end
	end

	return self
end

export type Label = typeof(Label.Prototype) & {
	label: string?,
	description: string?,
	component: apiTypes.ComponentObjects?,
	required: boolean?,
}

export type JSON = apiTypes.LabelComponentObject

return Label.Interface
