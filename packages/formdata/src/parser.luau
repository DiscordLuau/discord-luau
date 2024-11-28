--[[
	A multipart/form-data parser.

	This parser is based on the following spec(s):
		- https://www.rfc-editor.org/rfc/rfc2388
		- https://www.rfc-editor.org/rfc/rfc1867
		- https://www.rfc-editor.org/rfc/rfc2047
		- https://andreubotella.github.io/multipart-form-data/#multipart-form-data-parser
]]

local Stream = require("../luau_packages/stream")

local ILLEGAL_HTTP_TOKEN_CHARACTERS = table.freeze({
	['"'] = true,
	["("] = true,
	[")"] = true,
	[","] = true,
	["/"] = true,
	[":"] = true,
	[";"] = true,
	["<"] = true,
	["="] = true,
	[">"] = true,
	["?"] = true,
	["@"] = true,
	["["] = true,
	["]"] = true,
	["{"] = true,
	["}"] = true,
	["\20"] = true,
	["\9"] = true,
	["\r"] = true,
	["\n"] = true,
}) :: { [string]: boolean }

--[[
	Validate that the name of the Content-Disposition header is valid ABNF grammar as defined in RFC 2047.
]]
local function validateEncodedToken_RFC2047(source: string)
	local sourceSplit = string.split(source, "")

	for token in ILLEGAL_HTTP_TOKEN_CHARACTERS do
		local index = table.find(sourceSplit, token)

		if index then
			error(`Invalid form data: {source} (invalid encoded token)`)
		end
	end
end

--[[
	This function is responsible for parsing the Content-Disposition header.
]]
local function parseMultipartContentDisposition(stream: Stream.Stream): (string, string?)
	local header = stream:advance(20)

	assert(header, `Invalid form data: {stream.textSource} (unexpected end of stream)`)
	assert(
		string.lower(header) == "content-disposition:",
		`Invalid form data: {stream.textSource} (invalid content-disposition)`
	)

	-- skil all whitespaces
	stream:trim()

	assert(stream:advance(10) == "form-data;", `Invalid form data: {stream.textSource} (invalid content-disposition)`)

	-- skil all whitespaces
	stream:trim()

	local valueMap = stream:advanceUntil(function(character)
		return character == "\r"
	end)

	-- skip the newline
	stream:advance(1)

	assert(valueMap, `Invalid form data: {stream.textSource} (unexpected end of stream)`)

	local iterator = string.gmatch(valueMap, `"(%S+)"`)

	local name = iterator()
	local filename = iterator()

	assert(name, `Invalid form data: {stream.textSource} (invalid content-disposition)`)

	validateEncodedToken_RFC2047(name)

	name = string.gsub(name, "%%0A", "\n")
	name = string.gsub(name, "%%0D", "\r")
	name = string.gsub(name, "%%22", '"')

	return name, filename
end

--[[
	This function is responsible for parsing the Content-Type header.
]]
local function parseContentType(stream: Stream.Stream): string
	local header = stream:advance(13)

	assert(header, `Invalid form data: {stream.textSource} (unexpected end of stream)`)
	assert(string.lower(header) == "content-type:", `Invalid form data: {stream.textSource} (invalid content-type)`)

	-- skil all whitespaces
	stream:trim()

	local contentType = stream:advanceUntil(function(character)
		return character == "\r"
	end)

	-- skip the newline
	stream:advance(1)

	assert(contentType, `Invalid form data: {stream.textSource} (unexpected end of stream)`)

	contentType = string.sub(contentType, 1, #contentType - 1)

	return contentType
end

--[[
	This function is responsible for parsing the optional Content-Transfer-Encoding header.
]]
local function parseContentTransferEncoding(stream: Stream.Stream): string?
	local header = stream:peek(26)

	if header and string.lower(header) == "content-transfer-encoding:" then
		stream:advance(26)

		-- skil all whitespaces
		stream:trim()

		local contentTransferEncoding = stream:advanceUntil(function(character)
			return character == "\r"
		end)

		-- skip the newline
		stream:advance(1)

		assert(contentTransferEncoding, `Invalid form data: {stream.textSource} (unexpected end of stream)`)

		return contentTransferEncoding
	else
		return nil
	end
end

--[[
	This function is responsible for parsing the entire form data, it uses a combination of the above
		functions to parse the form data.
]]
local function parseMultipartFormDataValue(stream: Stream.Stream): DecodedFormDataValue
	local name, filename = parseMultipartContentDisposition(stream)
	local contentType = parseContentType(stream)
	local contentTransferEncoding = parseContentTransferEncoding(stream)

	assert(stream:advance(2) == "\r\n", `Invalid form data: {stream.textSource} (CR Ls)`)

	local body = stream:readUntilEnd()

	assert(body, `Invalid form data: {stream.textSource} (unexpected end of stream)`)

	return {
		name = name,
		filename = filename,
		contentType = contentType,
		contentTransferEncoding = contentTransferEncoding,
		body = body,
	}
end

--[[
	The main function that is called to parse the form data.
]]
local function parseMultipartFormData(stream: Stream.Stream, boundary: string): { DecodedFormDataValue }
	local formData = {}

	while true do
		-- assertions to ensure that the header is valid
		assert(stream:advance(2) == "--", `Invalid form data: {stream.textSource} (expected formdata boundary)`)
		assert(
			stream:advance(#boundary) == boundary,
			`Invalid form data: {stream.textSource} (expected formdata boundary)`
		)
		assert(stream:advance(2) == "\r\n", `Invalid form data: {stream.textSource} (CR Ls)`)

		-- get the body of the formdata entry
		local body = ""

		stream:advanceUntil(function(character)
			body ..= character

			return string.sub(body, -#`--{boundary}`) == `--{boundary}`
		end)

		local isLastEntry = stream:peek(4) == "--\r\n"

		-- reserve the boundary for the next iteration
		stream:advance(-(#boundary + 2))

		-- 6 for the last entry to cover: LF/CR/--
		body = string.sub(body, 1, #body - #boundary - 4)

		-- parse the form data body
		table.insert(formData, parseMultipartFormDataValue(Stream.new(body)))

		if isLastEntry then
			break
		end
	end

	return formData
end

--[[
	This function is responsible for parsing the mime type. Returning the 'boundary' from the mime parameters.
]]
local function parseMultipartMime(stream: Stream.Stream): string
	local matchedBoundary
	local boundary

	assert(
		stream:advance(19) == "multipart/form-data",
		`Invalid mime type: {stream.textSource} (expected formdata mime type)`
	)

	-- as defined in the examples in RFC1867 - ; can be used alongside , to split the parameters of this
	-- 		mime type
	assert(stream:peek() == ";" or stream:peek() == ",", `Invalid mime type: {stream.textSource} (unknown delimiter)`)

	-- skip the token since we only :peek() above
	stream:advance()

	-- skil all whitespaces
	stream:trim()

	-- read the boundary key/value pair
	boundary = stream:readUntilEnd()

	-- match the boundary value
	matchedBoundary = string.match(boundary, "boundary=(.+)")

	assert(matchedBoundary ~= nil, `Invalid mime type: {stream.textSource} (failed to match boundary)`)

	return matchedBoundary
end

export type DecodedFormDataValue = {
	name: string,
	filename: string?,
	contentType: string,
	contentTransferEncoding: string?,
	body: string,
}

return function(textSource: string, mimeType: string): { DecodedFormDataValue }
	local textSourceStream = Stream.new(textSource)
	local mimeTypeStream = Stream.new(mimeType)

	local boundary = parseMultipartMime(mimeTypeStream)

	return parseMultipartFormData(textSourceStream, boundary)
end
