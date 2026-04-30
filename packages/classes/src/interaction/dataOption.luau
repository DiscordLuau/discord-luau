--[=[
	@class Classes.Interactions.DataOption
	@__index Prototype

	Implementation of the Discord DataOption class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-type
]=]

--[=[
	@prop type ApplicationCommandOptionType
	@within Classes.Interactions.DataOption

	The type of command option this represents. This determines how the option is displayed and handled in Discord.
]=]

--[=[
	@prop options {Classes.Interactions.DataOption}?
	@within Classes.Interactions.DataOption

	An array of additional options if this option is a subcommand group, subcommand, or group of choices.
	Can be nil if this option has no sub-options.
]=]

--[=[
	@prop name string
	@within Classes.Interactions.DataOption

	The name of this command option as it appears in Discord. This is what users see when using the command.
]=]

--[=[
	@prop value T?
	@within Classes.Interactions.DataOption

	The value provided by the user for this option. The type varies based on the option type.
	Can be nil if no value was provided.
]=]

--[=[
	@prop focused boolean?
	@within Classes.Interactions.DataOption

	Indicates whether this option is currently focused in the Discord client during autocomplete.
	Only present for autocomplete interactions.
]=]

local apiTypes = require("../../luau_packages/api_types")

local DataOption = {}

DataOption.Interface = {}
DataOption.Prototype = {}

--[=[
	@within Classes.Interactions.DataOption
	@private

	Responsible for syncing data to this DataOption object. This is typically called by the API when this object is
	created or updated.
]=]
function DataOption.Prototype.sync<T>(
	self: DataOption<T>,
	optionData: apiTypes.ApplicationCommandInteractionDataOptionObject
)
	local optionArray = {}

	self.type = apiTypes.interaction.ApplicationCommandOptionType[optionData.type]

	for _, option in next, optionData.options or {} do
		table.insert(optionArray, DataOption.Interface.new(option))
	end

	self.options = optionArray

	self.name = optionData.name

	self.value = (optionData.value :: any) :: T

	self.focused = optionData.focused
end

--[=[
	@within Classes.Interactions.DataOption
	@private

	Responsible for constructing this class.
]=]
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
