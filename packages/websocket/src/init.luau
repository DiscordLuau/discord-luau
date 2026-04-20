local manager = require("@self/manager")
local shard = require("@self/shard")

export type Manager = manager.Manager

--[=[
	@class WebSocket

	Interface for the discord-luau WebSocket package
]=]

--[=[
	@prop manager WebSocket.Manager  
	@within WebSocket
]=]

--[=[
	@prop shard WebSocket.Shard 
	@within WebSocket
]=]

return {
	manager = manager,

	shard = shard,
}
