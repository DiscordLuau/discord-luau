--[=[
	@class Vendor.Signal

	The `Vendor.Signal` module is a third-party library used within Discord-Luau for creating and managing events and connections. This module may contain modifications to better integrate with the Discord-Luau framework.

	Original module can be found at: https://create.roblox.com/docs/reference/engine/datatypes/RBXScriptSignal

]=]
local Signal = require("Embedded/Devforum/Signal")

export type Signal<T...> = Signal.Signal<T...>
export type Connection = Signal.Connection

return Signal
