local ActionRowComponent = {}

ActionRowComponent.Type = "ActionRowComponent"

ActionRowComponent.Internal = {}
ActionRowComponent.Interface = {}
ActionRowComponent.Prototype = {
	Internal = ActionRowComponent.Internal,
}

function ActionRowComponent.Prototype:AddComponent(componentObject)
	assert(#self.Components + 1 <= 5, "Action Row objects can only contain up to five components!")

	table.insert(self.Components, componentObject)

	return self
end

function ActionRowComponent.Prototype:DestroyComponent(componentObject)
	local index = table.find(self.Components, componentObject)

	if index then
		table.remove(self.Components, index)
	end

	return self
end

function ActionRowComponent.Prototype:ToJSONObject()
	local components = {}

	for index, componentObject in self.Components do
		components[index] = componentObject:ToJSONObject()
	end

	return {
		type = 1,
		components = components
	}
end

function ActionRowComponent.Prototype:ToString()
	return `{ActionRowComponent.Type}`
end

function ActionRowComponent.Interface.new()
	return setmetatable({
		Components = { }
	}, {
		__index = ActionRowComponent.Prototype,
		__type = ActionRowComponent.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return ActionRowComponent.Interface
