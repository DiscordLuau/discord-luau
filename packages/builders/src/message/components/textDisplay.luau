--[=[
	@class Builders.Message.TextDisplay
	@__index Prototype

	Implementation of Discord's Text Display component as a Luau builder.

	https://discord.com/developers/docs/components/reference#text-display
]=]

--[=[
	@prop content string?
	@within Builders.Message.TextDisplay
	The markdown text content to display.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local TextDisplay = {}

TextDisplay.Prototype = {}
TextDisplay.Interface = {}

--[=[
	@within Builders.Message.TextDisplay

	Sets the markdown text content to display.
]=]
function TextDisplay.Prototype.setContent(self: TextDisplay, content: string): TextDisplay
	assert(#content >= 1, "content must be at least 1 character")

	self.content = content

	return self
end

--[=[
	@within Builders.Message.TextDisplay

	Responsible for building the TextDisplay JSON that can be parsed by the Discord API.
]=]
function TextDisplay.Prototype.build(self: TextDisplay): JSON
	assert(self.content, "TextDisplay.content is required")

	return {
		type = 10,
		content = self.content,
	}
end

--[=[
	@within Builders.Message.TextDisplay

	Responsible for creating a new TextDisplay.
]=]
function TextDisplay.Interface.new(resource: {
	content: string?,
}?): TextDisplay
	local self = setmetatable(
		{
			content = nil,
		} :: TextDisplay,
		{
			__index = TextDisplay.Prototype,
		}
	)

	if resource then
		if resource.content then
			self:setContent(resource.content)
		end
	end

	return self
end

export type TextDisplay = typeof(TextDisplay.Prototype) & {
	content: string?,
}

export type JSON = apiTypes.TextDisplayComponentObject

return TextDisplay.Interface
