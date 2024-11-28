return function(source: string)
	-- Check if the string is empty
	if source == "" then
		return false
	end

	-- Check if the string starts or ends with a hyphen
	if string.sub(source, 1, 1) == "-" or string.sub(source, -1) == "-" then
		return false
	end

	-- Split the string by hyphens
	local parts = string.split(source, "-")

	-- Check each part
	for _, part in ipairs(parts) do
		-- Check if the part is empty
		if part == "" then
			return false
		end

		-- Check if the part contains only lowercase letters and numbers
		if not string.match(part, "^[a-z0-9]+$") then
			return false
		end
	end

	-- If all checks pass, the string is valid kebab case
	return true
end
