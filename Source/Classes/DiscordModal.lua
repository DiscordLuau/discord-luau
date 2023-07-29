local DiscordModal = {}

DiscordModal.Type = "DiscordModal"

DiscordModal.Internal = {}
DiscordModal.Interface = {}
DiscordModal.Prototype = {
	Internal = DiscordModal.Internal,
}

function DiscordModal.Prototype:SetTitle(titleString)
	self.ModalTitle = titleString

	return self
end

function DiscordModal.Prototype:AddComponent(componentObject)
	assert(#self.Components + 1 <= 5, "Action Row objects can only contain up to five components!")

	table.insert(self.Components, componentObject)

	return self
end

function DiscordModal.Prototype:DestroyComponent(componentObject)
	local index = table.find(self.Components, componentObject)

	if index then
		table.remove(self.Components, index)
	end

	return self
end

function DiscordModal.Prototype:ToJSONObject()
	local components = {}

	for index, componentObject in self.Components do
		components[index] = componentObject:ToJSONObject()
	end

	return {
		title = self.ModalTitle,
		custom_id = self.ModalId,
		components = components
	}
end

function DiscordModal.Prototype:ToString()
	return `{DiscordModal.Type}<"{tostring(self.ModalTitle)}">`
end

function DiscordModal.Interface.new(modalId)
	return setmetatable({
		Components = {},
		ModalId = modalId
	}, {
		__index = DiscordModal.Prototype,
		__type = DiscordModal.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return DiscordModal.Interface
