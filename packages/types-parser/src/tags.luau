local MoonwaveTypes = require("@types/moonwaveTypes")

local Tags = {}

function Tags.getTags(packageObject: MoonwaveTypes.MoonwaveData)
	local tagObjects: { [string]: {string} } = {}
	local tagCount = 0

	if packageObject.tags then
		for _, tagString in packageObject.tags do
			local tagMetadata = string.split(tagString, " ")
			local tagName = table.remove(tagMetadata, 1) :: string

			tagCount += 1
			tagObjects[tagName] = tagMetadata
		end
	end

	return tagObjects, tagCount
end

return Tags