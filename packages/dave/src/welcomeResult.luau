--[=[
	@class Dave.WelcomeResult
	@__index Prototype

	Holds the outcome of processing an MLS welcome message via `Session:processWelcome`.

	A welcome message is sent by an existing group member when they commit a proposal to add this client. Processing
	it transitions the session into the group and exposes a change set against the session's previous roster: members
	added, or removed when their signature is empty. It is not the roster itself. After inspecting the result, call
	`destroy` to free the underlying handle.
]=]

--[=[
	@prop handle Sys.WelcomeResultHandle
	@within Dave.WelcomeResult
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")
local Sys = require("./sys")
local Buffer = require("./buffer")

local WelcomeResult = {}

WelcomeResult.Interface = {}
WelcomeResult.Prototype = {}

--[=[
	@within Dave.WelcomeResult

	Returns the user IDs whose keys changed against the session's previous roster, as decimal snowflake strings. On a
	session that never had a group this is every member, the bot included; a session that had one gets only the
	difference, because libdave never clears its roster. A removed member's `getRosterMemberSignature` is empty.
]=]
function WelcomeResult.Prototype.getRosterMemberIds(self: WelcomeResult): { string }
	local pointerSlot = Buffer.allocateSlot()
	local lengthSlot = Buffer.allocateSlot()
	local nullPointer = stdPolyfills.ffi.getNull()

	pointerSlot:writeptr(0, nullPointer)
	lengthSlot:writeptr(0, nullPointer)
	Sys.lib.daveWelcomeResultGetRosterMemberIds(self.handle, pointerSlot, lengthSlot)

	local results = Buffer.readU64ArrayAndFree(pointerSlot, lengthSlot)

	stdPolyfills.ffi.free(pointerSlot)
	stdPolyfills.ffi.free(lengthSlot)

	return results
end

--[=[
	@within Dave.WelcomeResult

	Returns the MLS credential signature for the roster member identified by `rosterId`
	(a decimal snowflake string). The signature bytes can be used to verify that the
	member's key package was signed by a trusted identity key.

	Empty for a member this welcome removed. Pass only an id from this result's `getRosterMemberIds`: libdave aborts
	the process for any other.
]=]
function WelcomeResult.Prototype.getRosterMemberSignature(self: WelcomeResult, rosterId: string): buffer
	local rosterIdBuffer = Buffer.u64StringToBuffer(rosterId)
	local dataSlot = Buffer.allocateSlot()
	local lengthSlot = Buffer.allocateSlot()

	Sys.lib.daveWelcomeResultGetRosterMemberSignature(self.handle, rosterIdBuffer :: any, dataSlot, lengthSlot)

	local result = Buffer.readLibBytes(dataSlot, lengthSlot)

	stdPolyfills.ffi.free(dataSlot)
	stdPolyfills.ffi.free(lengthSlot)

	return result
end

--[=[
	@within Dave.WelcomeResult

	Destroys the welcome result and frees all associated libdave resources. Must be called
	after the result has been fully inspected.
]=]
function WelcomeResult.Prototype.destroy(self: WelcomeResult)
	Sys.lib.daveWelcomeResultDestroy(self.handle)
end

--[=[
	@within Dave.WelcomeResult

	Constructs a WelcomeResult wrapper around an existing libdave handle. Called internally
	by `Session:processWelcome`.
]=]
function WelcomeResult.Interface.new(handle: Sys.WelcomeResultHandle): WelcomeResult
	return setmetatable({ handle = handle } :: WelcomeResult, { __index = WelcomeResult.Prototype })
end

export type WelcomeResult = typeof(WelcomeResult.Prototype) & {
	handle: Sys.WelcomeResultHandle,
}

return WelcomeResult.Interface
