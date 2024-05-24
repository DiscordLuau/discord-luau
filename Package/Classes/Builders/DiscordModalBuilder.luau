local Construct = require("../../Utils/Construct")
local ComponentTypes = require("../../Types/DiscordComponent")

--[=[
	@class DiscordModalBuilder

	DiscordModalBuilder is used to construct a modal dialog for a Discord interaction, including title and components.

	Usage:
	```lua
	local modal = DiscordModalBuilder.new("modal_id")
		:setTitle("Example Modal")
		:addComponent(ButtonBuilder.new("button_id"))
	```
]=]
local DiscordModalBuilder = {}

DiscordModalBuilder.Interface = {}
DiscordModalBuilder.Prototype = {}

DiscordModalBuilder.Prototype.type = "DiscordModalBuilder"

--[=[
	Sets the title of the modal.
	
	@method setTitle
	@param title string -- The title of the modal.
	@within DiscordModalBuilder
	@return DiscordModalBuilder -- Returns the DiscordModalBuilder instance for method chaining.
]=]
function DiscordModalBuilder.Prototype.setTitle(self: DiscordModalBuilder, title: string): DiscordModalBuilder
	self.modalTitle = title

	return self
end

--[=[
	Adds a component to the modal. The modal can contain up to five components.
	
	@method addComponent
	@param componentObject ComponentTypes.DiscordComponent -- The component to be added.
	@within DiscordModalBuilder
	@return DiscordModalBuilder -- Returns the DiscordModalBuilder instance for method chaining.
]=]
function DiscordModalBuilder.Prototype.addComponent(self: DiscordModalBuilder, componentObject: ComponentTypes.DiscordComponent): DiscordModalBuilder
	assert(#self.components + 1 <= 5, "Action Row objects can only contain up to five components!")

	table.insert(self.components, componentObject)

	return self
end

--[=[
	Converts the modal to a JSON object that can be sent to the Discord API.
	
	@method toJSONObject
	@within DiscordModalBuilder
	@return table -- The JSON representation of the modal.
]=]
function DiscordModalBuilder.Prototype.toJSONObject(self: DiscordModalBuilder)
	local components = {}

	for index, componentObject in self.components :: { any } do
		components[index] = componentObject:toJSONObject()
	end

	return {
		title = self.modalTitle,
		custom_id = self.modalId,
		components = components
	}
end

--[=[
	Creates a new instance of DiscordModalBuilder.
	
	@function new
	@within DiscordModalBuilder
	@param modalId string -- The ID of the modal.
	@return DiscordModalBuilder -- A new instance of DiscordModalBuilder.
]=]
function DiscordModalBuilder.Interface.new(modalId: string): DiscordModalBuilder
	return Construct({
		components = {},
		modalId = modalId
	}, DiscordModalBuilder.Prototype) :: any
end

export type DiscordModalBuilder = typeof(DiscordModalBuilder.Prototype) & {
	components: { ComponentTypes.DiscordComponent },
	modalId: string?,
	modalTitle: string?
}

return DiscordModalBuilder.Interface
