local Construct = require("../../Utils/Construct")
local ComponentTypes = require("../../Types/DiscordComponent")

--[=[
	@class DiscordModal

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordModal = {}

DiscordModal.Interface = {}
DiscordModal.Prototype = {}

DiscordModal.Prototype.type = "DiscordModal"

--[=[
	@method setTitle
	@within DiscordModal

	@param title string

	@return DiscordModal

	(yet-to-do!)

	```lua

	```
]=]
function DiscordModal.Prototype.setTitle(self: DiscordModal, title: string): DiscordModal
	self.modalTitle = title

	return self
end

--[=[
	@method addComponent
	@within DiscordModal

	@param componentObject !Interface

	@return DiscordModal

	(yet-to-do!)

	```lua

	```
]=]
function DiscordModal.Prototype.addComponent(self: DiscordModal, componentObject: ComponentTypes.DiscordComponent): DiscordModal
	assert(#self.components + 1 <= 5, "Action Row objects can only contain up to five components!")

	table.insert(self.components, componentObject)

	return self
end

--[=[
	@method toJSONObject
	@within DiscordModal

	@return { any }

	(yet-to-do!)

	```lua

	```
]=]
function DiscordModal.Prototype.toJSONObject(self: DiscordModal)
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
	@function new
	@within DiscordModal

	@param modalId string

	@return DiscordModal

	(yet-to-do!)

	```lua

	```
]=]
function DiscordModal.Interface.new(modalId: string): DiscordModal
	return Construct({
		components = {},
		modalId = modalId
	}, DiscordModal.Prototype) :: any
end

export type DiscordModal = typeof(DiscordModal.Prototype) & {
	components: { ComponentTypes.DiscordComponent },
	modalId: string?,
	modalTitle: string?
}

return DiscordModal.Interface