local Styleguide = {}

Styleguide.Interface = { }
Styleguide.Internal = { }
Styleguide.Prototype = {
	Internal = Styleguide.Internal
}

function Styleguide.Internal:ToPascalCase(sourceString)
	local underscoreSplitString = string.split(sourceString, "_")
	local source = ""

	for _, object in underscoreSplitString do
		source ..= string.upper(string.sub(object, 1, 1)) .. string.sub(object, 2, #object)
	end

	return source
end

function Styleguide.Prototype:PascalCase(targetObject)
	local object = targetObject or self.object
	local objectType = type(object)

	if objectType == "string" then
		return self.Internal:ToPascalCase(object)
	elseif objectType == "table" then
		local updatedTable = { }

		for index, value in object do
			index = self:PascalCase(index)

			if type(value) == "table" then
				value = self:PascalCase(value)
			end

			updatedTable[index] = value
		end

		return updatedTable
	end

	return targetObject
end

function Styleguide.Interface.new(object)
	return setmetatable({
		object = object,
	}, {
		__index = Styleguide.Prototype,
		__type = Styleguide.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return Styleguide.Interface
