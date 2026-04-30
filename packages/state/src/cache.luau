--[=[
	@class State.Cache
	@__index Prototype

	Class responsible for handling the underlying cache for all objects in Discord-Luau.

	Entries are evicted explicitly via `remove()` — callers must call this on DELETE gateway events.
	The previous weak-table + TTL-coroutine approach was removed because it could silently evict
	entries while they were still valid, and the coroutine workaround that prevented that eviction
	made the TTL meaningless.
]=]

--[=[
	@prop store { [K]: V }
	@within State.Cache
]=]

local Cache = {}

Cache.Interface = {}
Cache.Prototype = {}

--[=[
	@within State.Cache

	Stores a value in the cache under the given key.
]=]
function Cache.Prototype.set<K, V>(self: Cache<K, V>, key: K, value: V)
	self.store[key] = value
end

--[=[
	@within State.Cache

	Returns the cached value for the given key, or nil if not present.
]=]
function Cache.Prototype.get<K, V>(self: Cache<K, V>, key: K): V?
	return self.store[key :: any] :: any
end

--[=[
	@within State.Cache

	Removes the cached value for the given key. Call this on DELETE gateway events to keep
	the cache consistent with Discord's state.
]=]
function Cache.Prototype.remove<K, V>(self: Cache<K, V>, key: K)
	self.store[key] = nil
end

--[=[
	@within State.Cache

	Constructor for the Cache class.
]=]
function Cache.Interface.new<K, V>(): Cache<K, V>
	local self = setmetatable(
		{
			store = {} :: any,
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
}

return Cache.Interface
