--[=[
	@class Builders.Message.Modal
	@__index Prototype

	Implementation of discords Modal object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#text-input-object-text-input-structure
]=]

--[=[
	@prop customId string?
	@within Builders.Message.Modal
	The custom identifier for the modal.
]=]

--[=[
	@prop title string?
	@within Builders.Message.Modal
	The title that appears at the top of the modal.
]=]

--[=[
	@prop components { Builders.Message.TextInput }?
	@within Builders.Message.Modal
	The components that will be displayed in this modal.
]=]

local apiTypes = require("../../../luau_packages/api_types")

local textInput = require("./textInput")

local Modal = {}

Modal.Prototype = {}
Modal.Interface = {}

--[=[
	@within Builders.Message.Modal

	Sets the custom ID for this modal. This is required for the Discord API to identify this modal.
]=]
function Modal.Prototype.setCustomId(self: Modal, customId: string): Modal
	assert(#customId >= 1, "customId must be at least 1 character")
	assert(#customId <= 100, "customId must be at most 100 characters")

	self.customId = customId

	return self
end

--[=[
	@within Builders.Message.Modal

	Sets the title that appears at the top of the modal.
]=]
function Modal.Prototype.setTitle(self: Modal, title: string): Modal
	assert(#title >= 1, "title must be at least 1 character")
	assert(#title <= 45, "title must be at most 45 characters")

	self.title = title

	return self
end

--[=[
	@within Builders.Message.Modal

	Sets the components that will be displayed in this modal. These must be text input components.
]=]
function Modal.Prototype.setComponents(self: Modal, components: { textInput.JSON }): Modal
	self.components = components

	return self
end

--[=[
	@within Builders.Message.Modal

	Responsible for building the Modal JSON that can be parsed by the Discord API.
]=]
function Modal.Prototype.build(self: Modal): JSON
	assert(#(self.components or {}) <= 5, "modals cannot have more than 5 action rows")
	assert(self.customId, `Modal.customId is required.`)
	assert(self.title, `Modal.title is required.`)
	assert(self.components, `Modal.components is required.`)

	return {
		custom_id = self.customId,
		title = self.title,
		components = self.components,
	}
end

--[=[
	@within Builders.Message.Modal

	Responsible for creating a new Modal.

	```luau
	local modal = Modal.new()
		:setCustomId("my-modal")
		:setTitle("My Modal")
		:setComponents({textInput})
		:build()
	```
]=]
function Modal.Interface.new(resource: {
	customId: string?,
	title: string?,
	components: { textInput.JSON }?,
}?): Modal
	local self = setmetatable(
		{
			customId = nil,

			title = nil,

			components = nil,
		} :: Modal,
		{
			__index = Modal.Prototype,
		}
	)

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
