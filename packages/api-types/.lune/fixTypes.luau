--> Task responsible for bundling the API-Types package, as well as fixing types for said package because at the moment
--> types are not bundled via Darklua.

local fs = require("@lune/fs")

local stream = require("../luau_packages/stream")

local fileContent = fs.readFile("bundled.luau")
local fileTypes = {}

local hasFoundType = true

while hasFoundType do
	local cursor = string.find(fileContent, `export type`)

	if not cursor then
		hasFoundType = false

		continue
	end

	local stream = stream.new(fileContent, cursor + 11)
	local name, generics, definition = "", "", ""

	stream:trim()

	name = stream:advanceUntil(function(char: string)
		local isNotChar = string.match(char, "%a") == nil
		local isNotNumber = tonumber(char) == nil

		return isNotChar and isNotNumber
	end) :: string

	stream:trim()

	if string.sub(name, #name, #name) == "<" then
		name = string.sub(name, 1, #name - 1)

		generics = `<` .. stream:advanceUntil(function(char: string)
			return char == ">"
		end) :: string
	end

	stream:trim()
	stream:advance() -- skip '='
	stream:trim()

	local bracketScope = 0

	while true do
		definition ..= stream:advanceUntil(function(char)
			if char == "<" or char == "{" then
				bracketScope += 1
			end

			if char == ">" or char == "}" then
				bracketScope -= 1
			end

			return char == "\n"
		end) :: string

		if bracketScope > 0 then
			continue
		end

		stream:trim()

		if stream:peek() == "|" or stream:peek() == '"' then
			continue
		end

		break
	end

	fileContent = string.sub(fileContent, 1, cursor - 1) .. string.sub(fileContent, stream.cursorPosition, #fileContent)

	for _, phrase in { "objects.", "apiTypes." } do
		definition = string.gsub(definition, phrase, "")
	end

	table.insert(fileTypes, {
		name = name,
		generics = generics,
		definition = definition,
	})
end

local splitContent = string.split(fileContent, "\n")
local lastLineCount = 0

for index = #splitContent, 0, -1 do
	lastLineCount += 1

	if string.find(splitContent[index], "return {") then
		break
	end
end

for _, type in fileTypes do
	table.insert(
		splitContent,
		#splitContent - lastLineCount + 1,
		`export type {type.name}{type.generics or ""} = {type.definition}`
	)
end

-- warn(table.concat(splitContent, "\n"))

fs.writeFile("bundled.luau", table.concat(splitContent, "\n"))
