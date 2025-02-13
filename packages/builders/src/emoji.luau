--[[
	Implementation of discords Emoji object as a Luau builder.	

	https://discord.com/developers/docs/resources/emoji#emoji-object
]]

local util = require("../lune_packages/util")

local Emoji = {}

Emoji.Prototype = {}
Emoji.Interface = {}

--[[
	Set the ID of the emoji to use.
]]
function Emoji.Prototype.setId(self: Emoji, emojiId: string): Emoji
	self.emojiId = emojiId

	return self
end

--[[
	Set the name of the emoji to use.
]]
function Emoji.Prototype.setName(self: Emoji, emojiName: string): Emoji
	assert(util.validateKebabCase(emojiName), `Emoji names are Kebab case!`)

	self.emojiName = emojiName

	return self
end

--[[
	Responsible for building the Emoji JSON that can be parsed by the Discord API.
]]
function Emoji.Prototype.build(self: Emoji): JSON
	assert(self.emojiId, `Emoji ID is required.`)
	assert(self.emojiName, `Emoji name is required.`)

	return {
		id = self.emojiId,
		name = self.emojiName,
	}
end

--[[
	Responsible for creating a new Emoji.

	```lua
	
	```
]]
function Emoji.Interface.new(resource: {
	emojiId: string,
	emojiName: string,
}?): Emoji
	local self = setmetatable({} :: Emoji, {
		__index = Emoji.Prototype,
	})

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
