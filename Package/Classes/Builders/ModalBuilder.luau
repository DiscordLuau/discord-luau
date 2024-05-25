local Construct = require("../../Utils/Construct")

local ActionRowBuilder = require("Interface/ActionRowBuilder")
local ButtonBuilder = require("Interface/ButtonBuilder")
local SelectionBuilder = require("Interface/SelectionBuilder")
local TextInputBuilder = require("Interface/TextInputBuilder")

--[=[
	@class Builders.ModalBuilder

	ModalBuilder is used to construct a modal dialog for a Discord interaction, including title and components.

	Usage:
	```lua
	local modal = ModalBuilder.new("modal_id")
		:setTitle("Example Modal")
		:addComponent(ButtonBuilder.new("button_id"))
	```
]=]
local ModalBuilder = {}

ModalBuilder.Interface = {}
ModalBuilder.Prototype = {}

ModalBuilder.Prototype.type = "ModalBuilder"

--[=[
	Sets the title of the modal.
	
	@method setTitle
	@param title string -- The title of the modal.
	@within Builders.ModalBuilder
	@return Builders.ModalBuilder -- Returns the ModalBuilder instance for method chaining.
]=]
function ModalBuilder.Prototype.setTitle(self: ModalBuilder, title: string): ModalBuilder
	self.modalTitle = title

	return self
end

--[=[
	Adds a component to the modal. The modal can contain up to five components.
	
	@method addComponent
	@param componentObject DiscordComponentTypes.DiscordComponent -- The component to be added.
	@within Builders.ModalBuilder
	@return Builders.ModalBuilder -- Returns the ModalBuilder instance for method chaining.
]=]
function ModalBuilder.Prototype.addComponent(self: ModalBuilder, componentObject: InterfaceBuidler): ModalBuilder
	assert(#self.components + 1 <= 5, "Action Row objects can only contain up to five components!")

	table.insert(self.components, componentObject)

	return self
end

--[=[
	Converts the modal to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within Builders.ModalBuilder
	@return table -- The JSON representation of the modal.
]=]
function ModalBuilder.Prototype.toJSONObject(self: ModalBuilder)
	local components = {}

	for index, componentObject in self.components :: { any } do
		components[index] = componentObject:toJSONObject()
	end

	return {
		title = self.modalTitle,
		custom_id = self.modalId,
		components = components,
	}
end

--[=[
	Creates a new instance of ModalBuilder.
	
	@function new
	@within Builders.ModalBuilder
	@param modalId string -- The ID of the modal.
	@return Builders.ModalBuilder -- A new instance of ModalBuilder.
]=]
function ModalBuilder.Interface.new(modalId: string): ModalBuilder
	return Construct({
		components = {},
		modalId = modalId,
	}, ModalBuilder.Prototype) :: any
end

type InterfaceBuidler =
	ActionRowBuilder.ActionRowBuilder
	| ButtonBuilder.ButtonBuilder
	| SelectionBuilder.SelectionBuilder
	| TextInputBuilder.TextInputBuilder

export type ModalBuilder = typeof(ModalBuilder.Prototype) & {
	components: { InterfaceBuidler },
	modalId: string?,
	modalTitle: string?,
}

return ModalBuilder.Interface
