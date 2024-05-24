--[=[
	@class Vendor.Future

	The `Vendor.Future` module is a third-party library used within Discord-Luau for handling asynchronous operations. This module may contain modifications to better integrate with the Discord-Luau framework.

	Original module can be found at: https://util.redblox.dev/future.html

]=]
local Future = require("Embedded/Redblox/Future")

export type Future<T> = Future.Future<T>

return Future
