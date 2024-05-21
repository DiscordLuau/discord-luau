local Construct = require("../../Utils/Construct")
local ComponentTypes = require("../../Types/DiscordComponent")

--[=[
	@class DiscordModalBuilder

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordModalBuilder = {}

DiscordModalBuilder.Interface = {}
DiscordModalBuilder.Prototype = {}

DiscordModalBuilder.Prototype.type = "DiscordModalBuilder"

--[=[
	@method setTitle
	@within DiscordModalBuilder

	@param title string

	@return DiscordModalBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordModalBuilder.Prototype.setTitle(self: DiscordModalBuilder, title: string): DiscordModalBuilder
	self.modalTitle = title

	return self
end

--[=[
	@method addComponent
	@within DiscordModalBuilder

	@param componentObject !Interface

	@return DiscordModalBuilder

	(yet-to-do!)

	```lua

	```
]=]
function DiscordModalBuilder.Prototype.addComponent(self: DiscordModalBuilder, componentObject: ComponentTypes.DiscordComponent): DiscordModalBuilder
	assert(#self.components + 1 <= 5, "Action Row objects can only contain up to five components!")

	table.insert(self.components, componentObject)

	return self
end

--[=[
	@method toJSONObject
	@within DiscordModalBuilder

	@return { any }

	(yet-to-do!)

	```lua

	```
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
	@function new
	@within DiscordModalBuilder

	@param modalId string

	@return DiscordModalBuilder

	(yet-to-do!)

	```lua

	```
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