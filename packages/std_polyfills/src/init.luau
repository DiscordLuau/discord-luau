local task = require("@self/task")
local serde = require("@self/serde")
local process = require("@self/process")
local datetime = require("@self/datetime")
local net = require("@self/net")

export type DateTime = datetime.DateTime

export type WebSocket = net.WebSocket
export type FetchResponse = net.FetchResponse
export type FetchParams = net.FetchParams
export type HttpMethod = net.HttpMethod
export type HttpHeaderMap = net.HttpHeaderMap

--[=[
	@class StdPolyfills

	Std Polyfills is the technology that allows Discord-Luau to support multiple runtimes, it allows us to create a
		generated set of std functions that we call from the library.

	:::caution
	this package maintains polyfills required for discord-luau, not as polyfills for luau/other projects, if you're writing an
		application that wants to support multiple Runtimes, you're welcome to use StdPolyfills - but we're going to be very
		conservative on what APIs are available.

	it's recommended that you use an alternative polyfill/capabilities library.
	:::
]=]

return {
	--[=[
		@prop task StdPolyfills.task 
		@within StdPolyfills
	]=]
	task = task,

	--[=[
		@prop serde StdPolyfills.serde 
		@within StdPolyfills
	]=]
	serde = serde,

	--[=[
		@prop process StdPolyfills.process 
		@within StdPolyfills
	]=]
	process = process,

	--[=[
		@prop datetime StdPolyfills.datetime 
		@within StdPolyfills
	]=]
	datetime = datetime,

	--[=[
		@prop net StdPolyfills.net 
		@within StdPolyfills
	]=]
	net = net,
}
