--!nocheck
--# selene: allow(shadowing)

local Spawn = require("spawn")

local Task = require("@std/task")

export type Future<T...> = {
	valueList: { any }?,
	afterList: { (T...) -> () },
	yieldList: { thread },

	isComplete: (self: Future<T...>) -> boolean,
	isPending: (self: Future<T...>) -> boolean,

	expect: (self: Future<T...>, Message: string) -> T...,
	unwrap: (self: Future<T...>) -> T...,
	unwrapOr: (self: Future<T...>, T...) -> T...,
	unwrapOrElse: (self: Future<T...>, Else: () -> T...) -> T...,

	after: (self: Future<T...>, Callback: (T...) -> ()) -> (),
	await: (self: Future<T...>) -> T...,
}

local function isComplete<T...>(self: Future<T...>): boolean
	return self.valueList ~= nil
end

local function isPending<T...>(self: Future<T...>): boolean
	return self.valueList == nil
end

local function expect<T...>(self: Future<T...>, Message: string): T...
	assert(self.valueList, Message)

	return table.unpack(self.valueList)
end

local function unwrap<T...>(self: Future<T...>): T...
	return self:expect("Attempt to unwrap pending future!")
end

local function unwrapOr<T...>(self: Future<T...>, ...): T...
	if self.valueList then
		return table.unpack(self.valueList)
	else
		return ...
	end
end

local function unwrapOrElse<T...>(self: Future<T...>, Else: () -> T...): T...
	if self.valueList then
		return table.unpack(self.valueList)
	else
		return Else()
	end
end

local function after<T...>(self: Future<T...>, Callback: (T...) -> ()): T...
	if self.valueList then
		Spawn(Callback, table.unpack(self.valueList))
	else
		table.insert(self.afterList, Callback)
	end
end

local function await<T...>(self: Future<T...>): T...
	if self.valueList then
		return table.unpack(self.valueList)
	else
		table.insert(self.yieldList, coroutine.running())

		return coroutine.yield()
	end
end

local function Future<T..., A...>(Callback: (A...) -> T..., ...: A...): Future<T...>
	local self: Future<T...> = {
		valueList = nil,
		afterList = {},
		yieldList = {},

		isComplete = isComplete,
		isPending = isPending,

		expect = expect,
		unwrap = unwrap,
		unwrapOr = unwrapOr,
		unwrapOrElse = unwrapOrElse,

		after = after,
		await = await,
	} :: any

	Spawn(function(self: Future<T...>, Callback: (A...) -> T..., ...: A...)
		local valueList = { Callback(...) }
		self.valueList = valueList

		for _, Thread in self.yieldList do
			Task.spawn(Thread, table.unpack(valueList))
		end

		for _, Callback in self.afterList do
			Spawn(Callback, table.unpack(valueList))
		end
	end, self, Callback, ...)

	return self
end

local function Try<T..., A...>(Callback: (A...) -> T..., ...: A...): Future<T...>
	return Future(function(...)
		local data = { pcall(Callback, ...) }

		local success = table.remove(data, 1)

		if not success then
			error(data[1])
		end

		return table.unpack(data)
	end, ...)
end

return {
	new = Future,
	try = Try,
}
