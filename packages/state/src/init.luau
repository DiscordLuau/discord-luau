local rest = require("./rest")
local cache = require("./cache")
local state = require("./state")

export type State = state.State

--[=[
	@class State

	Interface for the discord-luau State package

	State represents some sort of data/persistant storage that is depended on from a multitude of components within the
		Discord-Luau library, for example - if you're going to make a Network request, you need access to some sort of state
		to derive the authorisation from.

	The state, cache and request states are handled under this package. They're responsible for handling the information
		discord-luau uses.
]=]

return {
	state = state,
	cache = cache,
	rest = rest,
}
