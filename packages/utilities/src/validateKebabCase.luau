--[=[
	@function Utilities.validateKebabCase
	@within Utilities

	Will validate a string to ensure that it's kebab-case, discord is sometimes very specific about the casing of
	text.

	Will return either true/false, will not error.

	@return thread
]=]
return function(source: string)
	if source == "" then
		return false
	end

	if string.sub(source, 1, 1) == "-" or string.sub(source, -1) == "-" then
		return false
	end

	local parts = string.split(source, "-")

	for _, part in ipairs(parts) do
		if part == "" then
			return false
		end

		if not string.match(part, "^[a-z0-9]+$") then
			return false
		end
	end

	return true
end
