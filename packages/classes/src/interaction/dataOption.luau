--[=[
	@class Classes.DataOption
	@__index Prototype

	Implementation of the Discord DataOption class in Luau

	https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-type
]=]

local apiTypes = require("../../lune_packages/api_types")

local DataOption = {}

DataOption.Interface = {}
DataOption.Prototype = {}

--[=[
	@within Classes.DataOption
	@private

	Responsible for syncing data to this DataOption object. This is typically called by the API when this object is
	created or updated.
]=]
function DataOption.Prototype.sync<T>(
	self: DataOption<T>,
	optionData: apiTypes.ApplicationCommandInteractionDataOptionObject
)
	local optionArray = {}

	--[=[
		@prop type ApplicationCommandOptionType
		@within Classes.DataOption

		The type of command option this represents. This determines how the option is displayed and handled in Discord.
	]=]
	self.type = apiTypes.application.ApplicationCommandOptionType[optionData.type]

	for _, option in next, optionData.options or {} do
		table.insert(optionArray, DataOption.Interface.new(option))
	end

	--[=[
		@prop options {Classes.DataOption}?
		@within Classes.DataOption

		An array of additional options if this option is a subcommand group, subcommand, or group of choices.
		Can be nil if this option has no sub-options.
	]=]
	self.options = optionArray

	--[=[
		@prop name string
		@within Classes.DataOption

		The name of this command option as it appears in Discord. This is what users see when using the command.
	]=]
	self.name = optionData.name

	--[=[
		@prop value T?
		@within Classes.DataOption

		The value provided by the user for this option. The type varies based on the option type.
		Can be nil if no value was provided.
	]=]
	self.value = (optionData.value :: any) :: T

	--[=[
		@prop focused boolean?
		@within Classes.DataOption

		Indicates whether this option is currently focused in the Discord client during autocomplete.
		Only present for autocomplete interactions.
	]=]
	self.focused = optionData.focused
end

--[=[
	@within Classes.DataOption
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
