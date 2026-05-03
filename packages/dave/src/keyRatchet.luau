--[=[
	@class Dave.KeyRatchet
	@__index Prototype

	An opaque handle to an MLS-derived key ratchet for a single participant.

	Key ratchets are obtained from `Session:getKeyRatchet(userId)` after the MLS group
	has been established.
	
	They are consumed by `Encryptor:setKeyRatchet` and `Decryptor:transitionToKeyRatchet` to
	enable authenticated encryption on a media stream. The underlying key material is owned
	by libdave; destroying the ratchet releases it.
]=]

--[=[
	@prop handle Sys.KeyRatchetHandle
	@within Dave.KeyRatchet
]=]

local Sys = require("./sys")

local KeyRatchet = {}

KeyRatchet.Interface = {}
KeyRatchet.Prototype = {}

--[=[
	@within Dave.KeyRatchet

	Destroys the key ratchet and releases the associated key material. The ratchet must
	not be used after this call. Note that the `Encryptor` and `Decryptor` do not take
	ownership of the ratchet handle, so it remains the caller's responsibility to destroy
	it when no longer needed.
]=]
function KeyRatchet.Prototype.destroy(self: KeyRatchet)
	Sys.lib.daveKeyRatchetDestroy(self.handle)
end

--[=[
	@within Dave.KeyRatchet

	Constructs a KeyRatchet wrapper around an existing libdave handle. Called internally
	by `Session:getKeyRatchet`.
]=]
function KeyRatchet.Interface.new(handle: Sys.KeyRatchetHandle): KeyRatchet
	return setmetatable({ handle = handle } :: KeyRatchet, { __index = KeyRatchet.Prototype })
end

export type KeyRatchet = typeof(KeyRatchet.Prototype) & {
	handle: Sys.KeyRatchetHandle,
}

return KeyRatchet.Interface
