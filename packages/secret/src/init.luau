--[=[
	@class Secret
	@__index Prototype

	Implementation of a basic secret object in Luau, primarily used to store bot tokens so that
	they can't be accidentally leaked into the console through a `print`

	```luau
	local a
	
	a = secret.new("SOMETHING_SECRET")
	print(a) --> "Secret(SOMETHIN--------)"

	a = secret.new(12222)
	print(a) --> "Secret(number)"
	```
]=]

local Secret = {}

Secret.Interface = {}
Secret.Prototype = {}

--[=[
	@within Secret

	Creates a new Secret
]=]
function Secret.Interface.new<T>(value: T): Secret<T>
	local self = setmetatable(
		{
			value = value,
		} :: Secret<T>,
		{
			__concat = function(_self: Secret<T>, otherValue: string)
				assert(typeof(_self.value) == "string", "Cannot concat a Secret with a non-string value.")

				return _self.value .. otherValue
			end,
			__eq = function(_self: Secret<T>, otherValue: string)
				return _self.value == otherValue
			end,
			__len = function(_self: Secret<T>)
				assert(
					typeof(_self.value) == "table" or typeof(_self.value) == "string",
					"Cannot length a Secret with a non-table/non-string value."
				)

				return #_self.value
			end,

			__index = Secret.Prototype,
			__metatabble = "The metatable is locked.",
			__newindex = function()
				error(`Cannot modify a Secret.`)
			end,
			__tostring = function(_self: Secret<T>)
				local typeOfValue = typeof(_self.value)

				if typeOfValue == "string" then
					local value = (_self.value :: any) :: string
					local sizeTohide = #value / 2

					return `Secret({string.sub(value, 1, #value - sizeTohide)}{string.rep("-", sizeTohide)})`
				else
					return `Secret({typeOfValue})`
				end
			end,
		}
	)

	return self
end

export type Secret<T> = typeof(Secret.Prototype) & {
	value: T,
}

return Secret.Interface
