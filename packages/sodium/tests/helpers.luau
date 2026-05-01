local function makeBuffer(s: string): buffer
	local b = buffer.create(#s)
	buffer.writestring(b, 0, s)
	return b
end

local function bufferEqual(a: buffer, b: buffer): boolean
	if buffer.len(a) ~= buffer.len(b) then
		return false
	end
	return buffer.readstring(a, 0, buffer.len(a)) == buffer.readstring(b, 0, buffer.len(b))
end

return {
	makeBuffer = makeBuffer,
	bufferEqual = bufferEqual,
}
