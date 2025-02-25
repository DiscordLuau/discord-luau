--[[
	Class responsible for handling the underlying cache for all objects in Discord-Luau
]]

local stdPolyfills = require("../lune_packages/std_polyfills")

local Cache = {}

Cache.Interface = {}
Cache.Prototype = {}

--[[
	Responsible for storing something in cache, will then store both the key and value so that these objects don't get
	cleaned up by the luau gc.
]]
function Cache.Prototype.set<K, V>(self: Cache<K, V>, key: K, value: V)
	self.store[key] = value

	coroutine.wrap(function()
		-- selene: allow(unused_variable)
		local keyRef: K? = key

		-- selene: allow(unused_variable)
		local keyValue: V? = value

		stdPolyfills.task.wait(self.expiry)

		keyRef = nil
		keyValue = nil
	end)()
end

--[[
	Responsible for getting something in the cache, will either return V or nil
]]
function Cache.Prototype.get<K, V>(self: Cache<K, V>, key: K): V?
	return self.store[key :: any] :: any
end

--[[
	Constructor for the Cache class.
]]
function Cache.Interface.new<K, V>(expiry: number): Cache<K, V>
	local self = setmetatable(
		{
			store = setmetatable({}, { __mode = "kv" }) :: any,

			expiry = expiry,
		} :: Cache<K, V>,
		{
			__index = Cache.Prototype,
		}
	)

	return self :: Cache<K, V>
end

export type Store<K, V> = { [K]: V }
export type Cache<K, V> = typeof(Cache.Prototype) & {
	store: Store<K, V>,

	expiry: number,
}

return Cache.Interface
