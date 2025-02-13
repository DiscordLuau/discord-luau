--[[
	Implementation of the Discord DefaultValue class in Luau

	https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-default-value-structure
]]

local apiTypes = require("../../../../lune_packages/api_types")

local DefaultValue = {}

DefaultValue.Interface = {}
DefaultValue.Prototype = {}

function DefaultValue.Prototype.sync(self: DefaultValue, valueData: apiTypes.SelectDefaultValueObject)
	self.id = valueData.id
	self.type = apiTypes.message.SelectDefaultValueType[valueData.type]
end

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
