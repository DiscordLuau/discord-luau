--[=[
	@class Builders.Message.Section
	@__index Prototype

	Implementation of Discord's Section component as a Luau builder.
	Sections lay out 1-3 text/button components with an optional right-side accessory.

	https://discord.com/developers/docs/components/reference#section
]=]

--[=[
	@prop components { TextDisplay.JSON | Button.JSON }
	@within Builders.Message.Section
	The child components. Maximum 3.
]=]

--[=[
	@prop accessory ComponentThumbnail.JSON | Button.JSON | nil
	@within Builders.Message.Section
	The right-side accessory component.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local Section = {}

Section.Prototype = {}
Section.Interface = {}

--[=[
	@within Builders.Message.Section

	Adds a text display or button component. Maximum 3 components.
]=]
function Section.Prototype.addComponent(
	self: Section,
	component: apiTypes.TextDisplayComponentObject | apiTypes.ButtonComponentObject
): Section
	assert(#self.components < 3, "sections cannot have more than 3 components")

	table.insert(self.components, component)

	return self
end

--[=[
	@within Builders.Message.Section

	Sets the right-side accessory. Can be a thumbnail or button.
]=]
function Section.Prototype.setAccessory(
	self: Section,
	accessory: apiTypes.ThumbnailComponentObject | apiTypes.ButtonComponentObject
): Section
	self.accessory = accessory

	return self
end

--[=[
	@within Builders.Message.Section

	Responsible for building the Section JSON that can be parsed by the Discord API.
]=]
function Section.Prototype.build(self: Section): JSON
	assert(#self.components >= 1, "sections must have at least 1 component")
	assert(self.accessory, "sections must have an accessory")

	return {
		type = 9,
		components = self.components,
		accessory = self.accessory,
	}
end

--[=[
	@within Builders.Message.Section

	Responsible for creating a new Section.
]=]
function Section.Interface.new(): Section
	local self = setmetatable(
		{
			components = {},
			accessory = nil,
		} :: Section,
		{
			__index = Section.Prototype,
		}
	)

	return self
end

export type Section = typeof(Section.Prototype) & {
	components: { apiTypes.TextDisplayComponentObject | apiTypes.ButtonComponentObject },
	accessory: (apiTypes.ThumbnailComponentObject | apiTypes.ButtonComponentObject)?,
}

export type JSON = apiTypes.SectionComponentObject

return Section.Interface
