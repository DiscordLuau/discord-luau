--[=[
	@class Builders.Message.Separator
	@__index Prototype

	Implementation of Discord's Separator component as a Luau builder.

	https://discord.com/developers/docs/components/reference#separator
]=]

--[=[
	@prop divider boolean?
	@within Builders.Message.Separator
	Whether to render a visible divider line. Defaults to true.
]=]

--[=[
	@prop spacing number?
	@within Builders.Message.Separator
	Spacing size: 1 for small, 2 for large.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local Separator = {}

Separator.Prototype = {}
Separator.Interface = {}

--[=[
	@within Builders.Message.Separator

	Sets whether a visible divider line is rendered.
]=]
function Separator.Prototype.setDivider(self: Separator, divider: boolean): Separator
	self.divider = divider

	return self
end

--[=[
	@within Builders.Message.Separator

	Sets the spacing size. 1 for small, 2 for large.
]=]
function Separator.Prototype.setSpacing(self: Separator, spacing: number): Separator
	assert(spacing == 1 or spacing == 2, "spacing must be 1 (small) or 2 (large)")

	self.spacing = spacing

	return self
end

--[=[
	@within Builders.Message.Separator

	Responsible for building the Separator JSON that can be parsed by the Discord API.
]=]
function Separator.Prototype.build(self: Separator): JSON
	return {
		type = 14,
		divider = self.divider,
		spacing = self.spacing,
	}
end

--[=[
	@within Builders.Message.Separator

	Responsible for creating a new Separator.
]=]
function Separator.Interface.new(resource: {
	divider: boolean?,
	spacing: number?,
}?): Separator
	local self = setmetatable(
		{
			divider = nil,
			spacing = nil,
		} :: Separator,
		{
			__index = Separator.Prototype,
		}
	)

	if resource then
		if resource.divider ~= nil then
			self:setDivider(resource.divider)
		end

		if resource.spacing then
			self:setSpacing(resource.spacing)
		end
	end

	return self
end

export type Separator = typeof(Separator.Prototype) & {
	divider: boolean?,
	spacing: number?,
}

export type JSON = apiTypes.SeparatorComponentObject

return Separator.Interface
