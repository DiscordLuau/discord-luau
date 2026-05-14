--[=[
	@function Utilities.validateCommandName
	@within Utilities

	Validates a string as a Discord application command name.
	Discord requires command names to be lowercase and only contain letters, numbers,
	hyphens, underscores, or apostrophes (1–32 characters).

	Will return either true/false, will not error.

	@return boolean
]=]
return function(source: string): boolean
	if #source < 1 or #source > 32 then
		return false
	end

	if not string.match(source, "^[a-z0-9%-%_']+$") then
		return false
	end

	return true
end
