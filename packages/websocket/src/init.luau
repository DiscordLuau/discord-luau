local manager = require("./manager")
local shard = require("./shard")

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
