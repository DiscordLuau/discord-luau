local IsUnique

IsUnique = function(dictionary0: { [any]: any }, dictionary1: { [any]: any })
	for key, value in dictionary0 do
		if type(value) == "table" then
			if not dictionary1[key] then
				return false
			end

			if IsUnique(value, dictionary1[key]) then
				return true
			end
		else
			if value ~= dictionary1[key] then
				return true
			end
		end
	end

	return false
end

return IsUnique
