local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

--[=[
	@function Utilities.createGuild
	@within Utilities

	Generates a random Guid (v4) that we can use to apply a unique identifier to objects.

	@return string
]=]
return function()
	local guid = string.gsub(template, "[xy]", function(c)
		local value = (c == "x") and math.random(0, 15) or math.random(8, 11)

		return string.format("%x", value)
	end)

	return guid
end
