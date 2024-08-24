--[[
	Implementation of a basic secret object in Luau, primarily used to store bot tokens so that
	they can't be accidentally leaked into the console through a `print`
]]

local Secret = {}

Secret.Interface = {}
Secret.Prototype = {}

function Secret.Interface.new(value: string): Secret
	local self = setmetatable(
		{
			value = value,
		} :: Secret,
		{
			__concat = function(_self: Secret, otherValue: string)
				return _self.value .. otherValue
			end,
			__eq = function(_self: Secret, otherValue: string)
				return _self.value == otherValue
			end,
			__len = function(_self: Secret)
				return #_self.value
			end,

			__index = Secret.Prototype,
			__metatabble = "The metatable is locked.",
			__newindex = function()
				error(`Cannot modify a Secret.`)
			end,
			__tostring = function(_self: Secret)
				if #_self.value < 20 then
					return "Secret(" .. string.rep("#", #_self.value) .. ")"
				end

				return `Secret({string.sub(_self.value, 1, #_self.value - 20)}####################)`
			end,
		}
	)

	return self
end

export type Secret = typeof(Secret.Prototype) & {
	value: string,
}

return Secret.Interface
