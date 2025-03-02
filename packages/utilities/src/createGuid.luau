local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

return function()
	local guid = string.gsub(template, "[xy]", function(c)
		local value = (c == "x") and math.random(0, 15) or math.random(8, 11)

		return string.format("%x", value)
	end)

	return guid
end
