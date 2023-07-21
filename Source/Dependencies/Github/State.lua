-- https://github.com/4x8Matrix/State/blob/Master/Source/init.lua

-- // External Imports
local Signal = require("Signal")

-- // Constants
local MAX_RECORD_ALLOCATION = 15

-- // Module
local State = {}

State.Type = "State"

State.Interface = {}
State.Prototype = {}

-- // Prototype functions
--[[
	Sets the state of recording, when recording all states will be saved into a history of states

	### Parameters
	- **state**: *boolean depicting the state*

	---
	Example:

	```lua
		local Value = State.new(0)
			:SetRecordingState(true)
	```
]]
function State.Prototype:SetRecordingState(state: boolean)
	self._recording = state

	return self
end

--[[
	Retrieves an array of previous states that have been set

	### Parameters
	- **count?**: *the amount of previous states you'd want to retrieve*

	---
	Example:

	```lua
		local Value = State.new(0)
			:SetRecordingState(true)
	```
]]
function State.Prototype:GetRecord(count: number): { any }
	if not count then
		return self._record
	end

	local record = {}

	for index = 1, count do
		record[index] = self._record[index]
	end

	return record
end

--[[
	Safe way to remove references to the `Value` as well as removing any generated content

	### Destroy

	---
	Example:

	```lua
		local Value = State.new(0)

		...

		Value:Destroy()
	```
]]
function State.Prototype:Destroy(): ()
	self._record = { }
	self.Value = nil

	self.Destroyed:Fire()
end

--[[
	Set the value of a state, when setting a state the 'Changed' signal will invoke.

	### Parameters
	- **value**: *the value we're setting*

	---
	Example:

	```lua
		local Value = State.new(0)

		Value:Set(1)
	```
]]
function State.Prototype:Set(value: any)
	local oldValue = self.Value

	if self._recording then
		table.insert(self._record, 1, value)

		if #self._record > MAX_RECORD_ALLOCATION then
			self._record[#self._record] = nil
		end
	end

	self.Value = value
	self.Changed:Fire(oldValue, value)
end

--[[
	Increments the value by a given input

	---
	Example:

	```lua
		local value = State.new(5)
			:Increment(5)

		print(value:Get()) -- 10
	```
]]
function State.Prototype:Increment(value: number)
	assert(
		type(self.Value) == "number",
		`Expected value to be a number when calling ':Increment', instead got {type(self.Value)}`
	)

	self:Set(self.Value + value)

	return self
end

--[[
	Decrement the value by a given input

	---
	Example:

	```lua
		local value = State.new(10)
			:Decrement(5)

		print(value:Get()) -- 5
	```
]]
function State.Prototype:Decrement(value: number)
	assert(
		type(self.Value) == "number",
		`Expected value to be a number when calling ':Decrement', instead got {type(self.Value)}`
	)

	self:Set(self.Value - value)

	return self
end

--[[
	Concat the value by a given input

	---
	Example:

	```lua
		local Value = State.new("Hello ")
			:Concat("World!")

		print(value:Get()) -- Hello World!
	```
]]
function State.Prototype:Concat(value: string)
	assert(
		type(self.Value) == "string",
		`Expected value to be a string when calling ':Concat', instead got {type(self.Value)}`
	)

	self:Set(self.Value .. value)

	return self
end

--[[
	Update the given value with a transform function

	---
	Example:

	```lua
		local Value = State.new("Hello ")
			:Update(function(value)
				return value .. "World!"
			end)

		print(value:Get()) -- Hello World!
	```
]]
function State.Prototype:Update(transform: (value: any) -> any)
	assert(
		type(transform) == "function",
		`Expected #1 parameter 'transform' to be a function when calling ':Update', instead got {type(transform)}`
	)

	self:Set(transform(self.Value))

	return self
end

--[[
	Fetches the value that the State currently holds.

	---
	Example:

	```lua
		local Value = State.new(0)
		local resolve = Value:Get()
	```
]]
function State.Prototype:Get(): any
	return self.Value
end

--[[
	Quick QoL function to observe any changes made to the states value

	### Parameters
	- **callbackFn**: *the callback function that'll connect to the 'Changed' event*

	---
	Example:

	```lua
		local Value = State.new(0)

		Value:Observe(function(oldValue, newValue)
			doSomething(oldValue, newValue)
		end)
	```
]]
function State.Prototype:Observe(callbackFn: (oldValue: any, newValue: any) -> ()): RBXScriptConnection
	return self.Changed:Connect(callbackFn)
end

--[[
	Returns a prettified string version of the state table.

	---
	Example:

	```lua
		local Value = State.new(0)

		print(tostring(Value)) -- Value<0>
	```
]]
function State.Prototype:ToString()
	return `{State.Type}<{tostring(self.Value)}>`
end

-- // Module functions
--[[
	Generate a new 'value' object

	### Parameters
	- **value**: *any object/type you'd want to store inside of the State*

	---
	Example:

	```lua
		local object = State.new("Hello, World!")

		...
	```
]]
function State.Interface.new(value: any)
	local self = setmetatable({ Value = value, _record = { value } }, {
		__type = State.Type,
		__index = State.Prototype,
		__tostring = function(object)
			return object:ToString()
		end,

	})

	self.Changed = Signal.new()
	self.Destroyed = Signal.new()

	return self
end

--[[
	Validate if an object is a 'State' object

	### Parameters
	- **object**: *potentially an 'State' object*

	---
	Example:

	```lua
		local object = State.new("Hello, World!")

		if State.is(object) then
			...
		end
	```
]]
function State.Interface.is(object): boolean
	if not object or type(object) ~= "table" then
		return false
	end

	local metatable = getmetatable(object)

	return metatable and metatable.__type == State.Type
end

return State.Interface