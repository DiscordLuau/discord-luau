local Construct = require("@Utils/Construct")

local Resolvable = require("@Network/Resolvable")

local ActionRowBuilder = require("@Builders/Interface/ActionRowBuilder")
local ButtonBuilder = require("@Builders/Interface/ButtonBuilder")
local SelectionBuilder = require("@Builders/Interface/SelectionBuilder")
local TextInputBuilder = require("@Builders/Interface/TextInputBuilder")

local ResolvableType = require("@Enums/ResolvableType")

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
	
	@method toPayloadObject
	@within Builders.ModalBuilder
	@return Network.Resolvable
]=]
function ModalBuilder.Prototype.toPayloadObject(self: ModalBuilder)
	local components = {}

	for index, componentObject in self.components :: { any } do
		components[index] = componentObject:toPayloadObject():resolve()
	end

	return Resolvable.new(ResolvableType.JSON, {
		title = self.modalTitle,
		custom_id = self.modalId,
		components = components,
	})
end

--[=[
	Creates a new instance of ModalBuilder.
	
	@function new
	@within Builders.ModalBuilder
	@param modalId string -- The ID of the modal.
	@return Builders.ModalBuilder -- A new instance of ModalBuilder.
]=]
function ModalBuilder.Interface.new(modalId: string)
	return (Construct({
		components = {},
		modalId = modalId,
	}, ModalBuilder.Prototype) :: unknown) :: ModalBuilder
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
