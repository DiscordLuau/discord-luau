--[=[
	@class Vendor.Signal

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local Signal = require("Embedded/Sleitnick/Signal")

export type Signal<T...> = Signal.Signal<T...>
export type Connection = Signal.Connection

return Signal