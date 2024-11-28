--[[
	Implementation of the Discord DataOption class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-type
]]

local apiTypes = require("../../lune_packages/api_types")

local DataOption = {}

DataOption.Interface = {}
DataOption.Prototype = {}

function DataOption.Prototype.sync<T>(
	self: DataOption<T>,
	optionData: apiTypes.ApplicationCommandInteractionDataOptionObject
)
	local optionArray = {}

	self.type = apiTypes.application.ApplicationCommandOptionType[optionData.type]

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
	type: apiTypes.ApplicationCommandOptionType,
	value: T?,
	options: { DataOption<T> }?,
	focused: boolean?,
}

return DataOption.Interface
