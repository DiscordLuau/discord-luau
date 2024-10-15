--[[
	Implementation of discords DefaultValue object as a Luau builder.	

	https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-default-value-structure
]]

local messageTypes = require("@api-types/message")

local DefaultValue = {}

DefaultValue.Prototype = {}
DefaultValue.Interface = {}

--[[
	
]]
function DefaultValue.Prototype.setId(self: DefaultValue, id: string): DefaultValue
	self.id = id

	return self
end

--[[
	
]]
function DefaultValue.Prototype.setType(self: DefaultValue, type: messageTypes.SelectDefaultValueType): DefaultValue
	self.type = type

	return self
end

--[[
	Responsible for building the DefaultValue JSON that can be parsed by the Discord API.
]]
function DefaultValue.Prototype.build(self: DefaultValue): JSON
	return {
		id = self.id,
		type = self.type,
	}
end

--[[
	Responsible for creating a new DefaultValue.

	```lua
	
	```
]]
function DefaultValue.Interface.new(resource: {
	id: string,
	type: messageTypes.SelectDefaultValueType,
}?): DefaultValue
	local self = setmetatable({} :: DefaultValue, {
		__index = DefaultValue.Prototype,
	})

	if resource then
		if resource.id then
			self:setId(resource.id)
		end

		if resource.type then
			self:setType(resource.type)
		end
	end

	return self
end

export type DefaultValue = typeof(DefaultValue.Prototype) & {
	id: string,
	type: messageTypes.SelectDefaultValueType,
}

export type JSON = typeof(DefaultValue.Prototype.build(nil :: any))

return DefaultValue.Interface
