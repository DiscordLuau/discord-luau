--[[
	Implementation of the Discord DataOption class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-type
]]

local apiTypes = require("@api-types/apiTypes")
local interactionTypes = require("@api-types/interaction")

local DataOption = {}

DataOption.Interface = {}
DataOption.Prototype = {}

function DataOption.Prototype.sync<T>(
	self: DataOption<T>,
	optionData: apiTypes.ApplicationCommandInteractionDataOptionObject
)
	local optionArray = {}

	self.type = (
		optionData.type == 1 and "SubCommand"
		or optionData.type == 2 and "SubCommandGroup"
		or optionData.type == 3 and "String"
		or optionData.type == 4 and "Integer"
		or optionData.type == 5 and "Boolean"
		or optionData.type == 6 and "User"
		or optionData.type == 7 and "Channel"
		or optionData.type == 8 and "Role"
		or optionData.type == 9 and "Mentionable"
		or optionData.type == 10 and "Number"
		or optionData.type == 11 and "Attachment"
	) :: interactionTypes.ApplicationCommandOptionType

	for _, option in next, optionData.options or {} do
		table.insert(optionArray, DataOption.Interface.new(option))
	end

	self.options = optionArray

	self.name = optionData.name
	self.value = (optionData.value :: any) :: T
	self.focused = optionData.focused
end

function DataOption.Interface.new<T>(optionData: apiTypes.ApplicationCommandInteractionDataOptionObject): DataOption<T>
	local self = setmetatable({} :: DataOption<T>, { __index = DataOption.Prototype })

	self:sync(optionData)

	return self
end

export type DataOption<T> = typeof(DataOption.Prototype) & {
	name: string,
	type: interactionTypes.ApplicationCommandOptionType,
	value: T?,
	options: { DataOption<T> }?,
	focused: boolean?,
}

return DataOption.Interface
