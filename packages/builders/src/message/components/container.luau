--[=[
	@class Builders.Message.Container
	@__index Prototype

	Implementation of Discord's Container component as a Luau builder.
	Containers are top-level wrappers for Components V2 layouts.
	Requires the IS_COMPONENTS_V2 message flag (bit 15) to be set.

	https://discord.com/developers/docs/components/reference#container
]=]

--[=[
	@prop components { any }
	@within Builders.Message.Container
	The child components. Maximum 40 total.
]=]

--[=[
	@prop accentColor number?
	@within Builders.Message.Container
	Hex color integer for the left border accent.
]=]

--[=[
	@prop spoiler boolean?
	@within Builders.Message.Container
	Whether the container contents are blurred as a spoiler.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local Container = {}

Container.Prototype = {}
Container.Interface = {}

--[=[
	@within Builders.Message.Container

	Adds a child component. Maximum 40 total components.
]=]
function Container.Prototype.addComponent(self: Container, component: apiTypes.ComponentObjects): Container
	assert(#self.components < 40, "containers cannot have more than 40 components")

	table.insert(self.components, component)

	return self
end

--[=[
	@within Builders.Message.Container

	Sets the accent color for the left border as a hex color integer.
]=]
function Container.Prototype.setAccentColor(self: Container, accentColor: number): Container
	self.accentColor = accentColor

	return self
end

--[=[
	@within Builders.Message.Container

	Sets whether the container contents are blurred as a spoiler.
]=]
function Container.Prototype.setSpoiler(self: Container, spoiler: boolean): Container
	self.spoiler = spoiler

	return self
end

--[=[
	@within Builders.Message.Container

	Responsible for building the Container JSON that can be parsed by the Discord API.
]=]
function Container.Prototype.build(self: Container): JSON
	assert(#self.components >= 1, "containers must have at least 1 component")

	return {
		type = 17,
		components = self.components,
		accent_color = self.accentColor,
		spoiler = self.spoiler,
	}
end

--[=[
	@within Builders.Message.Container

	Responsible for creating a new Container.
]=]
function Container.Interface.new(): Container
	local self = setmetatable(
		{
			components = {},
			accentColor = nil,
			spoiler = nil,
		} :: Container,
		{
			__index = Container.Prototype,
		}
	)

	return self
end

export type Container = typeof(Container.Prototype) & {
	components: { apiTypes.ComponentObjects },
	accentColor: number?,
	spoiler: boolean?,
}

export type JSON = apiTypes.ContainerComponentObject

return Container.Interface
