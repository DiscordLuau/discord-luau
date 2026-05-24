--[=[
	@class Builders.Emoji
	@__index Prototype

	Implementation of discords Emoji object as a Luau builder.	

	https://discord.com/developers/docs/resources/emoji#emoji-object
]=]

--[=[
	@prop emojiId string?
	@within Builders.Emoji
	The ID of the emoji.
]=]

--[=[
	@prop emojiName string?
	@within Builders.Emoji
	The name of the emoji.
]=]

local Emoji = {}

Emoji.Prototype = {}
Emoji.Interface = {}

--[=[
	@within Builders.Emoji

	Set the ID of the emoji to use.
]=]
function Emoji.Prototype.setId(self: Emoji, emojiId: string): Emoji
	self.emojiId = emojiId

	return self
end

--[=[
	@within Builders.Emoji

	Set the name of the emoji to use.
]=]
function Emoji.Prototype.setName(self: Emoji, emojiName: string): Emoji
	self.emojiName = emojiName

	return self
end

--[=[
	@within Builders.Emoji

	Responsible for building the Emoji JSON that can be parsed by the Discord API.
]=]
function Emoji.Prototype.build(self: Emoji): JSON
	assert(
		self.emojiId or self.emojiName,
		"Either emoji ID (for custom emoji) or emoji name (for Unicode emoji) is required."
	)

	return {
		id = self.emojiId,
		name = self.emojiName,
	}
end

--[=[
	@within Builders.Emoji

	Responsible for creating a new Emoji.

	```luau
	local emoji = Emoji.new({
		emojiId = "123456789",
		emojiName = "my-emoji"
	})
	```
]=]
function Emoji.Interface.new(resource: {
	emojiId: string,
	emojiName: string,
}?): Emoji
	local self = setmetatable(
		{
			emojiId = nil,

			emojiName = nil,
		} :: Emoji,
		{
			__index = Emoji.Prototype,
		}
	)

	if resource then
		if resource.emojiId then
			self:setId(resource.emojiId)
		end

		if resource.emojiName then
			self:setName(resource.emojiName)
		end
	end

	return self
end

export type Emoji = typeof(Emoji.Prototype) & {
	emojiId: string?,
	emojiName: string?,
}

export type JSON = typeof(Emoji.Prototype.build(nil :: any))

return Emoji.Interface
