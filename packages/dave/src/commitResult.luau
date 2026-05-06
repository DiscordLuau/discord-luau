--!strict
--!optimize 2
--!native

--[=[
	@class Dave.CommitResult
	@__index Prototype

	Holds the outcome of applying an MLS commit message via `Session:processCommit`.

	A commit can succeed (the group epoch advanced), be ignored (the commit was redundant
	or out-of-order), or fail hard (the commit was malformed). On hard failure,
	`Session:processCommit` logs an error before returning — inspect `isFailed` only if
	you need to handle the ignored case separately.

	After inspecting the result, call `destroy` to free the underlying handle.
]=]

--[=[
	@prop handle Sys.CommitResultHandle
	@within Dave.CommitResult
	@private

	Opaque handle to the underlying libdave commit result object.
]=]

local stdPolyfills = require("../luau_packages/std_polyfills")
local Sys = require("./sys")
local Buffer = require("./buffer")

local CommitResult = {}

CommitResult.Interface = {}
CommitResult.Prototype = {}

--[=[
	@within Dave.CommitResult

	Returns `true` if the commit was hard-rejected by the library. A failed commit
	indicates a protocol violation; the session should be reset.
]=]
function CommitResult.Prototype.isFailed(self: CommitResult): boolean
	return Sys.lib.daveCommitResultIsFailed(self.handle) ~= 0
end

--[=[
	@within Dave.CommitResult

	Returns `true` if the commit was soft-rejected (ignored). This typically means the
	commit was a duplicate or arrived out of order. No epoch transition occurred and the
	session state is unchanged.
]=]
function CommitResult.Prototype.isIgnored(self: CommitResult): boolean
	return Sys.lib.daveCommitResultIsIgnored(self.handle) ~= 0
end

--[=[
	@within Dave.CommitResult

	Returns the user IDs of every member in the group roster after the commit was applied,
	as a list of decimal snowflake strings. An empty list means no members remain (the
	group was torn down).
]=]
function CommitResult.Prototype.getRosterMemberIds(self: CommitResult): { string }
	local pointerSlot = Buffer.allocateSlot()
	local lengthSlot = Buffer.allocateSlot()

	Sys.lib.daveCommitResultGetRosterMemberIds(self.handle, pointerSlot, lengthSlot)

	local results = Buffer.readU64ArrayAndFree(pointerSlot, lengthSlot)

	stdPolyfills.ffi.free(pointerSlot)
	stdPolyfills.ffi.free(lengthSlot)

	return results
end

--[=[
	@within Dave.CommitResult

	Returns the MLS credential signature for the roster member identified by `rosterId`
	(a decimal snowflake string). The signature bytes can be used to verify that the
	member's key package was signed by a trusted identity key.
]=]
function CommitResult.Prototype.getRosterMemberSignature(self: CommitResult, rosterId: string): buffer
	local rosterIdBuffer = Buffer.u64StringToBuffer(rosterId)
	local dataSlot = Buffer.allocateSlot()
	local lengthSlot = Buffer.allocateSlot()

	Sys.lib.daveCommitResultGetRosterMemberSignature(self.handle, rosterIdBuffer :: any, dataSlot, lengthSlot)

	local result = Buffer.readLibBytes(dataSlot, lengthSlot)

	stdPolyfills.ffi.free(dataSlot)
	stdPolyfills.ffi.free(lengthSlot)

	return result
end

--[=[
	@within Dave.CommitResult

	Destroys the commit result and frees all associated libdave resources. Must be called
	after the result has been fully inspected.
]=]
function CommitResult.Prototype.destroy(self: CommitResult)
	Sys.lib.daveCommitResultDestroy(self.handle)
end

--[=[
	@within Dave.CommitResult
	@private

	Constructs a CommitResult wrapper around an existing libdave handle. Called internally
	by `Session:processCommit`.
]=]
function CommitResult.Interface.new(handle: Sys.CommitResultHandle): CommitResult
	return setmetatable({ handle = handle } :: CommitResult, { __index = CommitResult.Prototype })
end

export type CommitResult = typeof(CommitResult.Prototype) & {
	handle: Sys.CommitResultHandle,
}

return CommitResult.Interface
