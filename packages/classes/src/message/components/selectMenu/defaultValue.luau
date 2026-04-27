--[=[
	@class Classes.Message.SelectMenuDefaultValue
	@__index Prototype

	Implementation of the Discord DefaultValue class in Luau

	https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-default-value-structure
]=]

--[=[
	@prop id string
	@within Classes.Message.SelectMenuDefaultValue

	The ID of the default value. This is typically a snowflake ID representing a user, role, channel or other Discord entity
	depending on the select menu type.
]=]

--[=[
	@prop type string
	@within Classes.Message.SelectMenuDefaultValue

	The type of select menu option this default value represents. This corresponds to one of the SelectDefaultValueType
	values and determines what kind of entity the ID refers to.
]=]

local apiTypes = require("../../../../luau_packages/api_types")

local DefaultValue = {}

DefaultValue.Interface = {}
DefaultValue.Prototype = {}

--[=[
	@within Classes.Message.SelectMenuDefaultValue
	@private

	Responsible for syncing data to this DefaultValue object. This is typically called by the API when this object is
	created or updated.
]=]
function DefaultValue.Prototype.sync(self: DefaultValue, valueData: apiTypes.SelectDefaultValueObject)
	self.id = valueData.id

	self.type = apiTypes.message.SelectDefaultValueType[valueData.type]
end
--[=[
	@within Classes.Message.SelectMenuDefaultValue
	@private

	Responsible for constructing this class.
]=]
function DefaultValue.Interface.new(valueData: apiTypes.SelectDefaultValueObject): DefaultValue
	local self = setmetatable({} :: DefaultValue, { __index = DefaultValue.Prototype })

	self:sync(valueData)

	return self
end

export type DefaultValue = typeof(DefaultValue.Prototype) & {
	id: apiTypes.Snowflake,
	type: apiTypes.SelectDefaultValueType,
}

return DefaultValue.Interface
