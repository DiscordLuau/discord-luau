return function(runtime: string): string?
	if string.lower(runtime) ~= "zune" then
		return nil
	end

	return [[globals:
  zune:
    any: true
]]
end
