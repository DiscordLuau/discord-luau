--[=[
	@class Vendor.Console

	The `Vendor.Console` module is a third-party library used within Discord-Luau for logging and debugging purposes. This module may contain modifications to better integrate with the Discord-Luau framework.

	Original module can be found at: https://docs.asyncmatrix.dev/Packages/Console

]=]
local Console = require("Embedded/4x8Matrix/Console")

export type Console = Console.Console

return Console
