return function<K, V>(dictionary: { [K]: V }): { K }
	local result = {}

	for key in dictionary do
		table.insert(result, key)
	end

	return result
end
