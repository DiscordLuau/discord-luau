return function<T>(source: T): T
	if type(source) ~= "table" then
		return source
	else
		for key: unknown, value: unknown in source do
			source[key] = value
		end
	end

	return source
end
