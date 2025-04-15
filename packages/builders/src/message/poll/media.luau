--[=[
	@class Builders.PollMedia
	@__index Prototype

	Implementation of discords PollMedia object as a Luau builder.	

	https://discord.com/developers/docs/resources/poll#poll-media-object-poll-media-object-structure
]=]

local emojiBuilder = require("../../emoji")

local PollMedia = {}

PollMedia.Prototype = {}
PollMedia.Interface = {}

--[=[
	@within Builders.PollMedia

	Sets the text for the PollMedia.
]=]
function PollMedia.Prototype.setText(self: PollMedia, text: string): PollMedia
	self.text = text

	return self
end

--[=[
	@within Builders.PollMedia

	Responsible for setting the emoji for the PollMedia.
]=]
function PollMedia.Prototype.setEmoji(self: PollMedia, emoji: emojiBuilder.JSON): PollMedia
	self.emoji = emoji

	return self
end

--[=[
	@within Builders.PollMedia

	Responsible for building the PollMedia JSON that can be parsed by the Discord API.
]=]
function PollMedia.Prototype.build(self: PollMedia): JSON
	return {
		text = self.text,
		emoji = self.emoji,
	}
end

--[=[
	@within Builders.PollMedia

	Responsible for creating a new PollMedia.

	```luau
	local media = PollMedia.new({
		text = "Sample text",
		emoji = emojiBuilder.new():build()
	})
	```
]=]
function PollMedia.Interface.new(resource: {
	text: string?,
	emoji: emojiBuilder.JSON?,
}?): PollMedia
	local self = setmetatable(
		{
			--[=[
				@prop text string?
				@within Builders.PollMedia
				The text content of the poll media.
			]=]
			text = nil,

			--[=[
				@prop emoji Builders.Emoji?
				@within Builders.PollMedia
				The emoji associated with this poll media.
			]=]
			emoji = nil,
		} :: PollMedia,
		{
			__index = PollMedia.Prototype,
		}
	)

	if resource then
		if resource.text then
			self:setText(resource.text)
		end

		if resource.emoji then
			self:setEmoji(resource.emoji)
		end
	end

	return self
end

export type PollMedia = typeof(PollMedia.Prototype) & {
	text: string?,
	emoji: emojiBuilder.JSON?,
}

export type JSON = typeof(PollMedia.Prototype.build(nil :: any))

return PollMedia.Interface
