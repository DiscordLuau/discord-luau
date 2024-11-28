return function(source)
	local reversed = {}

	for i, v in source do
		reversed[v] = i
	end

	return setmetatable(source, {
		__index = reversed,
	})
end
