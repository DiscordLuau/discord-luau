--> Task responsible for bundling the API-Types package, as well as fixing types for said package because at the moment
--> types are not bundled via Darklua.

local fs = require("@lune/fs")

local CHARACTER_PRIORITY_MAP = table.freeze({
	'"',
	"{",
})

local fileContent = fs.readFile("bundled.luau")
local typesToAdd = {}

for type, darkluaId in string.gmatch(fileContent, "type%s+(%w+)(_+DARKLUA_TYPE_[%w_]+)") do
	local _, endPoint = string.find(fileContent, `type {type}{darkluaId}`)
	local generics = ""
	local priority = ""

	if endPoint then
		local nextChar = string.sub(fileContent, endPoint + 1, endPoint + 1)
		local hasGenerics = nextChar == "<"

		if hasGenerics then
			local endOfGeneric = string.find(fileContent, ">", endPoint)

			generics = string.sub(fileContent, endPoint + 1, endOfGeneric)
		end

		local equalsPoint = string.find(fileContent, "=", endPoint)
		local nextCharPoint = equalsPoint and string.find(fileContent, "(%S+)", equalsPoint + 1)
		local nextChar = nextCharPoint and string.sub(fileContent, nextCharPoint, nextCharPoint)

		priority = nextChar or ""
	end

	if not typesToAdd[type] then
		typesToAdd[type] = {}
	end

	table.insert(typesToAdd[type], {
		definition = `export type {type}{generics} = {type}{darkluaId}{generics}\n`,
		priority = priority,
	})
end

-- modify this!
for _, definitions in typesToAdd do
	table.sort(definitions, function(a, b)
		local indexA = table.find(CHARACTER_PRIORITY_MAP, a.priority) or 1000
		local indexB = table.find(CHARACTER_PRIORITY_MAP, b.priority) or 1000

		return indexA < indexB
	end)

	local definition = definitions[1].definition

	fileContent = `{definition}{fileContent}`
end

fs.writeFile("bundled.luau", `--!nonstrict\n--# selene: allow(unused_variable)\n\n{fileContent}`)
