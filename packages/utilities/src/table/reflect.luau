--[=[
	@function Utilities.tableReflect
	@within Utilities

	Will swap the K, V's, as well as keep the original K, Vs, for example:

	```luau
	local a = { a = 1, b = 2, c = 3 }
	
	tableReflect(a)
	
	--[[
	a = {
		-- default values
		a = 1,
		b = 2,
		c = 3,
		-- reflected values
		[1] = "a",
		[2] = "b",
		[3] = "c"
	}
	]]
	```

	@return table
]=]
return function(source)
	local result = {}

	for key, value in source do
		result[key] = value
		result[value] = key
	end

	return result
end
