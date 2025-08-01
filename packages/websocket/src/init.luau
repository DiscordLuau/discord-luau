local manager = require("@self/manager")
local shard = require("@self/shard")

export type Manager = manager.Manager

--[=[
	@class WebSocket

	Interface for the discord-luau WebSocket package
]=]

return {
	--[=[
		@prop manager WebSocket.Manager  
		@within WebSocket
	]=]
	manager = manager,

	--[=[
		@prop shard WebSocket.Shard 
		@within WebSocket
	]=]
	shard = shard,
}
