--[[
	Implementation of discords Modal object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#text-input-object-text-input-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local textInput = require("./textInput")

local Modal = {}

Modal.Prototype = {}
Modal.Interface = {}

--[[
	
]]
function Modal.Prototype.setCustomId(self: Modal, customId: string): Modal
	self.customId = customId

	return self
end

--[[
	
]]
function Modal.Prototype.setTitle(self: Modal, title: string): Modal
	self.title = title

	return self
end

--[[
	
]]
function Modal.Prototype.setComponents(self: Modal, components: { textInput.JSON }): Modal
	self.components = components

	return self
end

--[[
	Responsible for building the Modal JSON that can be parsed by the Discord API.
]]
function Modal.Prototype.build(self: Modal): JSON
	assert(self.customId, `Modal.customId is required.`)
	assert(self.title, `Modal.title is required.`)
	assert(self.components, `Modal.components is required.`)

	return {
		custom_id = self.customId,
		title = self.title,
		components = self.components,
	}
end

--[[
	Responsible for creating a new Modal.

	```lua
	
	```
]]
function Modal.Interface.new(resource: {
	customId: string?,
	title: string?,
	components: { textInput.JSON }?,
}?): Modal
	local self = setmetatable({} :: Modal, {
		__index = Modal.Prototype,
	})

	if resource then
		if resource.customId then
			self:setCustomId(resource.customId)
		end

		if resource.title then
			self:setTitle(resource.title)
		end

		if resource.components then
			self:setComponents(resource.components)
		end
	end

	return self
end

export type Modal = typeof(Modal.Prototype) & {
	customId: string?,
	title: string?,
	components: { textInput.JSON }?,
}

export type JSON = apiTypes.InteractionCallbackModalObject

return Modal.Interface
