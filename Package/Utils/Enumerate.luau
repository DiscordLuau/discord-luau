local Enumeration = {}

Enumeration.Type = "Enumeration"

Enumeration.Interface = { }
Enumeration.Prototype = { }

function Enumeration.Prototype:Is(item)
	for _, value in self do
		if item == value then
			return true
		end
	end

	return false
end

function Enumeration.Prototype:ToString()
	return `{Enumeration.Type}<"{table.concat(self, ", ")}">`
end

function Enumeration.Interface.new(items)
	return setmetatable(items :: any, {
		__index = Enumeration.Prototype,
		__type = Enumeration.Type,
		__iter = function(...)
			return next, ...
		end,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

return Enumeration.Interface