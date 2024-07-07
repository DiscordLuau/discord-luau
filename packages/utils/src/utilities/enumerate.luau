--[[
	Create a list of enumerated values.
]]

local Enumeration = {}

Enumeration.Type = "Enumeration"

function Enumeration:Is(item)
	for _, value in self do
		if item == value then
			return true
		end
	end

	return false
end

function Enumeration:Assert(item)
	assert(self:Is(item), `EnumItem is invalid!`)
end

function Enumeration:ToString()
	return `{Enumeration.Type}<"{table.concat(self, ", ")}">`
end

return function<S>(items: S): S & typeof(Enumeration)
	return setmetatable(items :: any, {
		__index = Enumeration,
		__type = Enumeration.Type,
		__iter = function(...)
			return next, ...
		end,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end
