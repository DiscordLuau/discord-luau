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

local METATABLE_LOCK = "The metatable is locked."

local function isSecret(value: any): boolean
	return getmetatable(value) == METATABLE_LOCK
end

--[=[
	@within Secret

	Creates a new Secret
]=]
function Secret.Interface.new<T>(value: T): Secret<T>
	local data = { value = value }

	local self = setmetatable({} :: Secret<T>, {
		__index = function(_, key)
			if key == "value" then
				return data.value
			end
			return Secret.Prototype[key]
		end,
		__newindex = function()
			error(`Cannot modify a Secret.`)
		end,
		__concat = function(left, right)
			if isSecret(left) then
				local secretValue = (left :: Secret<any>).value
				assert(typeof(secretValue) == "string", "Cannot concat a Secret with a non-string value.")
				return secretValue .. (right :: string)
			else
				local secretValue = (right :: Secret<any>).value
				assert(typeof(secretValue) == "string", "Cannot concat a Secret with a non-string value.")
				return (left :: string) .. secretValue
			end
		end,
		__eq = function(left, right)
			local leftValue = isSecret(left) and (left :: Secret<any>).value or left
			local rightValue = isSecret(right) and (right :: Secret<any>).value or right
			return leftValue == rightValue
		end,
		__len = function(_self: Secret<T>)
			assert(
				typeof(_self.value) == "table" or typeof(_self.value) == "string",
				"Cannot length a Secret with a non-table/non-string value."
			)

			return #(_self.value :: any)
		end,
		__metatable = METATABLE_LOCK,
		__tostring = function(_self: Secret<T>)
			local typeOfValue = typeof(_self.value)

			if typeOfValue == "string" then
				local value = (_self.value :: any) :: string
				local visibleCount = math.floor(#value / 2)

				return `Secret({string.sub(value, 1, visibleCount)}{string.rep("-", #value - visibleCount)})`
			else
				return `Secret({typeOfValue})`
			end
		end,
	})

	return self :: any
end

export type Secret<T> = {
	value: T,
}

return Secret.Interface
