--[=[
	@class Formdata
	@__index Prototype

	A multipart/form-data implementation for luau.
	
	This implementation is based on the following spec(s):
	- https://www.rfc-editor.org/rfc/rfc2388
	- https://xhr.spec.whatwg.org/#formdata
]=]

local parser = require("@self/parser")

local FILE_FORMATS = table.freeze({
	jpg = "image/jpg",
	jpeg = "image/jpeg",
	png = "image/png",
	webp = "image/webp",
	gif = "image/gif",

	csv = "text/csv",
	txt = "text/plain",
	css = "text/css",
	js = "text/javascript",
	html = "text/html",

	mp4 = "video/mp4",
	json = "application/json",
})

local FormData = {}

FormData.Interface = {}
FormData.Prototype = {}

--[[
	QoL function to filter an array with a predicate, returns the index and value of the first item that
		matches the predicate
]]
local function filter<T>(array, predicate: (T) -> boolean, after: number?): (number?, T?)
	for index = after or 1, #array do
		local value = array[index]

		if predicate(value) then
			return index, value
		end
	end

	return nil
end

--[[
	responsible for generating a UUID that we use in the compilation of the formdata object.
]]
local function uuid()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

	return string.gsub(template, "[xy]", function(c)
		local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)

		return string.format("%x", v)
	end)
end

--[=[
	@within Formdata

	Not included in the spec, but we need this to be able to get the body for the formdata object.
]=]
function FormData.Prototype.getBody(self: FormData): string
	local multiformContent = ""

	for _, entry in self.entries do
		local fileType = entry.encoding or string.match(entry.filename or "", ".+%.(%S+)")

		multiformContent ..= `--{self.boundary}\r\n`
		multiformContent ..= `Content-Disposition: form-data; name="{entry.name}"{entry.filename and `; filename="{entry.filename}"` or ""}\r\n`
		multiformContent ..= `Content-Type: {FILE_FORMATS[fileType] or "application/octet-stream"}\r\n`

		multiformContent ..= `\r\n`
		multiformContent ..= `{entry.value}\r\n`
	end

	multiformContent ..= `--{self.boundary}--\r\n`

	return multiformContent
end

--[=[
	@within Formdata

	Not included in the spec, but we need this to be able to get the header for the formdata object.
]=]
function FormData.Prototype.getHeader(self: FormData): string
	return `multipart/form-data; boundary={self.boundary}`
end

--[=[
	@within Formdata

	Appends a new entry to the form data's internal 'entries' table.
]=]
function FormData.Prototype.append(
	self: FormData,
	name: string,
	value: string,
	filename: string?,
	encoding: string?
): ()
	table.insert(self.entries, {
		name = name,
		value = value,
		filename = filename,
		encoding = encoding,
	})
end

--[=[
	@within Formdata

	Sets the name, value and filename of an entry in the form data's internal 'entries' table.

	Follows the standard found here: https://xhr.spec.whatwg.org/#dom-formdata-append
]=]
function FormData.Prototype.set(self: FormData, name: string, value: string, filename: string?, encoding: string?): ()
	local index = filter(self.entries, function(object)
		return object.name == name
	end)

	--[[
		If there are entries in this’s entry list whose name is name,
			then replace the first such entry with entry and remove the others.

		Otherwise, append entry to this’s entry list.
	]]

	if index then
		self.entries[index] = {
			name = name,
			value = value,
			filename = filename,
			encoding = encoding,
		}

		local nextIndex = filter(self.entries, function(object)
			return object.name == name
		end, index)

		while nextIndex do
			table.remove(self.entries, nextIndex)

			nextIndex = filter(self.entries, function(object)
				return object.name == name
			end, index)
		end
	else
		self:append(name, value, filename, encoding)
	end
end

--[=[
	@within Formdata

	Function responsible for the removal of a formdata entry from the formdata's internal 'entries' table.
]=]
function FormData.Prototype.delete(self: FormData, name: string): ()
	local index = filter(self.entries, function(object)
		return object.name == name
	end)

	if index then
		table.remove(self.entries, index)
	end
end

--[=[
	@within Formdata

	Function responsible for checking if this formdata object has a specific entry.
]=]
function FormData.Prototype.has(self: FormData, name: string): boolean
	local _, formDataEntryValue = filter(self.entries, function(object)
		return object.name == name
	end)

	return formDataEntryValue ~= nil
end

--[=[
	@within Formdata

	Function responsible for getting the value of a formdata entry from the formdata's internal 'entries' table.
]=]
function FormData.Prototype.get(self: FormData, name: string): FormDataEntryValue?
	local _, formDataEntryValue = filter(self.entries, function(object)
		return object.name == name
	end)

	return (formDataEntryValue and formDataEntryValue.value) or nil
end

--[=[
	@within Formdata

	Function responsible for getting all the values of a formdata entry from the formdata's internal 'entries' table.

	If a name is provided, it will only return the values of all entries with the provided name.
]=]
function FormData.Prototype.getAll(self: FormData, name: string?): { FormDataEntryValue }
	local entries = {}

	if name then
		local lastIndex
		local formDataEntryValue

		while true do
			lastIndex, formDataEntryValue = filter(self.entries, function(object)
				return object.name == name
			end, lastIndex)

			if not lastIndex or not formDataEntryValue then
				break
			end

			table.insert(entries, (formDataEntryValue :: FormDataEntryMap).value)
		end
	else
		for _, entry in self.entries do
			table.insert(entries, entry.value)
		end
	end

	return entries
end

--[=[
	@within Formdata

	Constructor for the FormData object.

	This function is missing the form and submitter fields that are defined in the spec, but are not relevant for the
		implementation of this feature in luau.
]=]
function FormData.Interface.new(): FormData
	local entries = {}

	return setmetatable(
		{
			entries = entries,
			boundary = uuid(),
		} :: FormData,
		{
			__index = FormData.Prototype,
			__iter = entries,
		}
	)
end

--[=[
	@within Formdata

	Parses formdata a string into a FormData object.
]=]
function FormData.Interface.parse(textSource: string, mimeType: string): FormData
	local formData = FormData.Interface.new()
	local parsedFiles = parser(textSource, mimeType)

	for _, entry in parsedFiles do
		formData:append(entry.name, entry.body, entry.filename, entry.contentTransferEncoding)
	end

	return formData
end

export type FormDataEntryValue = string
export type FormDataEntryMap = { name: string, value: string, filename: string?, encoding: string? }
export type FormData = typeof(FormData.Prototype) & {
	entries: { FormDataEntryMap },
	boundary: string,
}

return FormData.Interface
