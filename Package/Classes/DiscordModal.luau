local Construct = require("../Utils/Construct")
local ComponentTypes = require("../Types/DiscordComponent")

--[=[
	@class DiscordModal

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordModal = {}

DiscordModal.Interface = {}
DiscordModal.Prototype = {}

DiscordModal.Prototype.type = "DiscordModal"

function DiscordModal.Prototype.setTitle(self: DiscordModal, titleString: string): DiscordModal
	self.ModalTitle = titleString

	return self
end

function DiscordModal.Prototype.addComponent(self: DiscordModal, componentObject: ComponentTypes.DiscordComponent): DiscordModal
	assert(#self.components + 1 <= 5, "Action Row objects can only contain up to five components!")

	table.insert(self.components, componentObject)

	return self
end

function DiscordModal.Prototype.destroyComponent(self: DiscordModal, componentObject: ComponentTypes.DiscordComponent): DiscordModal
	local index = table.find(self.components, componentObject)

	if index then
		table.remove(self.components, index)
	end

	return self
end

function DiscordModal.Prototype.toJSONObject(self: DiscordModal)
	local components = {}

	for index, componentObject in (self.components :: {}) do
		components[index] = componentObject:toJSONObject()
	end

	return {
		title = self.ModalTitle,
		custom_id = self.modalId,
		components = components
	}
end

function DiscordModal.Interface.new(modalId: string)
	return Construct({
		components = {},
		modalId = modalId
	}, DiscordModal.Prototype)
end

export type DiscordModal = typeof(DiscordModal.Prototype) & {
	components: { ComponentTypes.DiscordComponent },
	modalId: string?
}

return DiscordModal.Interface