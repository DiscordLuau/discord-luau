--[=[
	@class Sodium.Sys

	Raw FFI bindings for libsodium.
	Loads the shared library and exposes the complete C API as a typed Luau interface.
	Prefer the higher-level modules in `Sodium` over calling `lib` directly.
]=]

--[=[
	@prop lib Lib
	@within Sodium.Sys

	The loaded libsodium FFI library handle. All libsodium functions are called through this.
]=]

--[=[
	@prop aes256gcm { KEY_BYTES: number, NONCE_BYTES: number, TAG_BYTES: number }
	@within Sodium.Sys
]=]

--[=[
	@prop chacha20poly1305 { KEY_BYTES: number, NONCE_BYTES: number, TAG_BYTES: number }
	@within Sodium.Sys
]=]

--[=[
	@prop xchacha20poly1305 { KEY_BYTES: number, NONCE_BYTES: number, TAG_BYTES: number }
	@within Sodium.Sys
]=]

--[=[
	@prop secretbox { KEY_BYTES: number, NONCE_BYTES: number, MAC_BYTES: number }
	@within Sodium.Sys
]=]

--[=[
	@prop box { PUBLIC_KEY_BYTES: number, SECRET_KEY_BYTES: number, NONCE_BYTES: number, MAC_BYTES: number, BEFORENM_BYTES: number }
	@within Sodium.Sys
]=]

--[=[
	@prop sign { PUBLIC_KEY_BYTES: number, SECRET_KEY_BYTES: number, BYTES: number }
	@within Sodium.Sys
]=]

--[=[
	@prop generichash { BYTES: number, BYTES_MIN: number, BYTES_MAX: number, KEY_BYTES: number, KEY_BYTES_MIN: number, KEY_BYTES_MAX: number }
	@within Sodium.Sys
]=]

--[=[
	@prop hash { SHA256_BYTES: number, SHA512_BYTES: number }
	@within Sodium.Sys
]=]

--[=[
	@prop auth { BYTES: number, KEY_BYTES: number }
	@within Sodium.Sys
]=]

--[=[
	@prop kdf { BYTES_MIN: number, BYTES_MAX: number, CONTEXT_BYTES: number, KEY_BYTES: number }
	@within Sodium.Sys
]=]

--[=[
	@prop pwhash { BYTES_MIN: number, BYTES_MAX: number, SALT_BYTES: number, STR_BYTES: number, ALG_ARGON2ID13: number, OPSLIMIT_INTERACTIVE: number, MEMLIMIT_INTERACTIVE: number, OPSLIMIT_MODERATE: number, MEMLIMIT_MODERATE: number, OPSLIMIT_SENSITIVE: number, MEMLIMIT_SENSITIVE: number }
	@within Sodium.Sys
]=]

--[=[
	@prop base64 { VARIANT_ORIGINAL: number, VARIANT_ORIGINAL_NO_PADDING: number, VARIANT_URLSAFE: number, VARIANT_URLSAFE_NO_PADDING: number }
	@within Sodium.Sys
]=]

local binary = require("../luau_packages/binary")
local stdPolyfills = require("../luau_packages/std_polyfills")

if not stdPolyfills.runtime.capabilities().ffi then
	local function makeStub(name: string): any
		return setmetatable({} :: any, {
			__index = function(_, key)
				return makeStub(`{name}.{key}`)
			end,
			__call = function()
				error(`Sodium requires FFI which is not available on this runtime (accessed: {name})`)
			end,
		})
	end
	return makeStub("Sodium.Sys")
end

local types = stdPolyfills.ffi.getTypes()

local void = types.void
local u32 = types.u32
local u64 = types.u64
local i32 = types.i32
local pointer = types.pointer

local cSizeT = u64

export type Lib = {
	sodium_init: () -> number,

	crypto_aead_aes256gcm_is_available: () -> number,

	crypto_aead_aes256gcm_keygen: (k: FFIPointer) -> (),

	crypto_aead_aes256gcm_encrypt: (
		c: FFIPointer,
		cipherLengthPointer: FFIPointer,
		m: FFIPointer,
		mlen: number,
		ad: FFIPointer,
		adlen: number,
		nsec: FFIPointer,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_aead_aes256gcm_decrypt: (
		m: FFIPointer,
		messageLengthPointer: FFIPointer,
		nsec: FFIPointer,
		c: FFIPointer,
		clen: number,
		ad: FFIPointer,
		adlen: number,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_aead_aes256gcm_encrypt_detached: (
		c: FFIPointer,
		mac: FFIPointer,
		macLengthPointer: FFIPointer,
		m: FFIPointer,
		mlen: number,
		ad: FFIPointer,
		adlen: number,
		nsec: FFIPointer,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_aead_aes256gcm_decrypt_detached: (
		m: FFIPointer,
		nsec: FFIPointer,
		c: FFIPointer,
		clen: number,
		mac: FFIPointer,
		ad: FFIPointer,
		adlen: number,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,

	crypto_aead_chacha20poly1305_ietf_keygen: (k: FFIPointer) -> (),

	crypto_aead_chacha20poly1305_ietf_encrypt: (
		c: FFIPointer,
		cipherLengthPointer: FFIPointer,
		m: FFIPointer,
		mlen: number,
		ad: FFIPointer,
		adlen: number,
		nsec: FFIPointer,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_aead_chacha20poly1305_ietf_decrypt: (
		m: FFIPointer,
		messageLengthPointer: FFIPointer,
		nsec: FFIPointer,
		c: FFIPointer,
		clen: number,
		ad: FFIPointer,
		adlen: number,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_aead_chacha20poly1305_ietf_encrypt_detached: (
		c: FFIPointer,
		mac: FFIPointer,
		macLengthPointer: FFIPointer,
		m: FFIPointer,
		mlen: number,
		ad: FFIPointer,
		adlen: number,
		nsec: FFIPointer,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_aead_chacha20poly1305_ietf_decrypt_detached: (
		m: FFIPointer,
		nsec: FFIPointer,
		c: FFIPointer,
		clen: number,
		mac: FFIPointer,
		ad: FFIPointer,
		adlen: number,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,

	crypto_aead_xchacha20poly1305_ietf_keygen: (k: FFIPointer) -> (),

	crypto_aead_xchacha20poly1305_ietf_encrypt: (
		c: FFIPointer,
		cipherLengthPointer: FFIPointer,
		m: FFIPointer,
		mlen: number,
		ad: FFIPointer,
		adlen: number,
		nsec: FFIPointer,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_aead_xchacha20poly1305_ietf_decrypt: (
		m: FFIPointer,
		messageLengthPointer: FFIPointer,
		nsec: FFIPointer,
		c: FFIPointer,
		clen: number,
		ad: FFIPointer,
		adlen: number,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_aead_xchacha20poly1305_ietf_encrypt_detached: (
		c: FFIPointer,
		mac: FFIPointer,
		macLengthPointer: FFIPointer,
		m: FFIPointer,
		mlen: number,
		ad: FFIPointer,
		adlen: number,
		nsec: FFIPointer,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_aead_xchacha20poly1305_ietf_decrypt_detached: (
		m: FFIPointer,
		nsec: FFIPointer,
		c: FFIPointer,
		clen: number,
		mac: FFIPointer,
		ad: FFIPointer,
		adlen: number,
		npub: FFIPointer,
		k: FFIPointer
	) -> number,

	crypto_secretbox_keygen: (k: FFIPointer) -> (),

	crypto_secretbox_easy: (
		c: FFIPointer,
		m: FFIPointer,
		mlen: number,
		n: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_secretbox_open_easy: (
		m: FFIPointer,
		c: FFIPointer,
		clen: number,
		n: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_secretbox_detached: (
		c: FFIPointer,
		mac: FFIPointer,
		m: FFIPointer,
		mlen: number,
		n: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_secretbox_open_detached: (
		m: FFIPointer,
		c: FFIPointer,
		mac: FFIPointer,
		mlen: number,
		n: FFIPointer,
		k: FFIPointer
	) -> number,

	crypto_box_keypair: (pk: FFIPointer, sk: FFIPointer) -> number,
	crypto_box_beforenm: (k: FFIPointer, pk: FFIPointer, sk: FFIPointer) -> number,

	crypto_box_easy: (
		c: FFIPointer,
		m: FFIPointer,
		mlen: number,
		n: FFIPointer,
		pk: FFIPointer,
		sk: FFIPointer
	) -> number,
	crypto_box_open_easy: (
		m: FFIPointer,
		c: FFIPointer,
		clen: number,
		n: FFIPointer,
		pk: FFIPointer,
		sk: FFIPointer
	) -> number,
	crypto_box_detached: (
		c: FFIPointer,
		mac: FFIPointer,
		m: FFIPointer,
		mlen: number,
		n: FFIPointer,
		pk: FFIPointer,
		sk: FFIPointer
	) -> number,
	crypto_box_open_detached: (
		m: FFIPointer,
		c: FFIPointer,
		mac: FFIPointer,
		mlen: number,
		n: FFIPointer,
		pk: FFIPointer,
		sk: FFIPointer
	) -> number,
	crypto_box_easy_afternm: (
		c: FFIPointer,
		m: FFIPointer,
		mlen: number,
		n: FFIPointer,
		k: FFIPointer
	) -> number,
	crypto_box_open_easy_afternm: (
		m: FFIPointer,
		c: FFIPointer,
		clen: number,
		n: FFIPointer,
		k: FFIPointer
	) -> number,

	crypto_sign_keypair: (pk: FFIPointer, sk: FFIPointer) -> number,
	crypto_sign_ed25519_sk_to_pk: (pk: FFIPointer, sk: FFIPointer) -> number,

	crypto_sign_detached: (
		sig: FFIPointer,
		signatureLengthPointer: FFIPointer,
		m: FFIPointer,
		mlen: number,
		sk: FFIPointer
	) -> number,
	crypto_sign_verify_detached: (sig: FFIPointer, m: FFIPointer, mlen: number, pk: FFIPointer) -> number,

	crypto_generichash_statebytes: () -> number,

	crypto_generichash: (
		out: FFIPointer,
		outlen: number,
		in_: FFIPointer,
		inlen: number,
		key: FFIPointer,
		keylen: number
	) -> number,
	crypto_generichash_init: (state: FFIPointer, key: FFIPointer, keylen: number, outlen: number) -> number,
	crypto_generichash_update: (state: FFIPointer, in_: FFIPointer, inlen: number) -> number,
	crypto_generichash_final: (state: FFIPointer, out: FFIPointer, outlen: number) -> number,

	crypto_hash_sha256: (out: FFIPointer, in_: FFIPointer, inlen: number) -> number,
	crypto_hash_sha512: (out: FFIPointer, in_: FFIPointer, inlen: number) -> number,

	crypto_auth_keygen: (k: FFIPointer) -> (),

	crypto_auth: (out: FFIPointer, in_: FFIPointer, inlen: number, k: FFIPointer) -> number,
	crypto_auth_verify: (h: FFIPointer, in_: FFIPointer, inlen: number, k: FFIPointer) -> number,

	crypto_kdf_keygen: (key: FFIPointer) -> (),

	crypto_kdf_derive_from_key: (
		subkey: FFIPointer,
		subkeylen: number,
		subkeyId: number,
		ctx: FFIPointer,
		key: FFIPointer
	) -> number,

	crypto_pwhash: (
		out: FFIPointer,
		outlen: number,
		passwd: FFIPointer,
		passwdlen: number,
		salt: FFIPointer,
		opslimit: number,
		memlimit: number,
		alg: number
	) -> number,
	crypto_pwhash_str: (
		out: FFIPointer,
		passwd: FFIPointer,
		passwdlen: number,
		opslimit: number,
		memlimit: number
	) -> number,
	crypto_pwhash_str_verify: (str: FFIPointer, passwd: FFIPointer, passwdlen: number) -> number,
	crypto_pwhash_str_needs_rehash: (str: FFIPointer, opslimit: number, memlimit: number) -> number,

	randombytes_buf: (buf: FFIPointer, size: number) -> (),
	randombytes_uniform: (upperBound: number) -> number,

	sodium_memcmp: (b1: FFIPointer, b2: FFIPointer, len: number) -> number,
	sodium_memzero: (pnt: FFIPointer, len: number) -> (),

	sodium_bin2hex: (hex: FFIPointer, hexMaxlen: number, bin: FFIPointer, binLen: number) -> FFIPointer,
	sodium_hex2bin: (
		bin: FFIPointer,
		binMaxlen: number,
		hex: FFIPointer,
		hexLen: number,
		ignore: FFIPointer,
		binLen: FFIPointer,
		hexEnd: FFIPointer
	) -> number,

	sodium_base64_encoded_len: (binLen: number, variant: number) -> number,
	sodium_bin2base64: (
		b64: FFIPointer,
		b64Maxlen: number,
		bin: FFIPointer,
		binLen: number,
		variant: number
	) -> FFIPointer,
	sodium_base642bin: (
		bin: FFIPointer,
		binMaxlen: number,
		b64: FFIPointer,
		b64Len: number,
		ignore: FFIPointer,
		binLen: FFIPointer,
		b64End: FFIPointer,
		variant: number
	) -> number,
}

local platform = stdPolyfills.process.getPlatform()
local rawArch = stdPolyfills.process.getArch()
local architecture = if rawArch == "aarch64" then "arm64" elseif rawArch == "x86" then "x86" else "x64"

local checksums: { [string]: string } = {
	["linux-arm64"] = "sha256:dccbbedba8d50c4dca0061d4255e3cc6ff11e3def564b3b4ac0efac3da22b915",
	["linux-x64"] = "sha256:13373e2914d27a8796568de878e62242f1076dc9c05ee6c6e31c71df829c10e2",
	["macos-arm64"] = "sha256:f8d4e805cc5426b11eaad5d8782f38a414b4666868e019526ff7228439433b35",
	["macos-x64"] = "sha256:391fd170b4dc52f91a9c123e12e55bcdb75b320e88f79df654250a2171db6dca",
	["windows-x64"] = "sha256:f1485ce247ce946e2c17ee2c56811c22838703309c7944a03867bbc45ce91cf9",
	["windows-x86"] = "sha256:ada13ecb6fe5bd7bc5b9e7d256639c40bcb00794c58b8bb21abea0b090601ada",
}

local result = binary.load({
	id = "libsodium",
	version = "0.0.1",
	url = "https://raw.githubusercontent.com/DiscordLuau/discord-luau/refs/tags/sodium-{version}/packages/sodium/binaries/{os}-{arch}/libsodium{ext}",
	checksum = checksums[`{platform}-{architecture}`]
		or error(`Unsupported platform '{platform}-{architecture}' for libsodium`),
})

local lib = (
	stdPolyfills.ffi.dlopen(result.path, {
		--  AEAD: AES-256-GCM

		crypto_aead_aes256gcm_is_available = { returns = i32, args = {} },
		crypto_aead_aes256gcm_keygen = { returns = void, args = { pointer } },
		crypto_aead_aes256gcm_encrypt = {
			returns = i32,
			args = { pointer, pointer, pointer, cSizeT, pointer, cSizeT, pointer, pointer, pointer },
		},
		crypto_aead_aes256gcm_decrypt = {
			returns = i32,
			args = { pointer, pointer, pointer, pointer, cSizeT, pointer, cSizeT, pointer, pointer },
		},
		crypto_aead_aes256gcm_encrypt_detached = {
			returns = i32,
			args = { pointer, pointer, pointer, pointer, cSizeT, pointer, cSizeT, pointer, pointer, pointer },
		},
		crypto_aead_aes256gcm_decrypt_detached = {
			returns = i32,
			args = { pointer, pointer, pointer, cSizeT, pointer, pointer, cSizeT, pointer, pointer },
		},

		--  AEAD: ChaCha20-Poly1305 (IETF)

		crypto_aead_chacha20poly1305_ietf_keygen = { returns = void, args = { pointer } },
		crypto_aead_chacha20poly1305_ietf_encrypt = {
			returns = i32,
			args = { pointer, pointer, pointer, cSizeT, pointer, cSizeT, pointer, pointer, pointer },
		},
		crypto_aead_chacha20poly1305_ietf_decrypt = {
			returns = i32,
			args = { pointer, pointer, pointer, pointer, cSizeT, pointer, cSizeT, pointer, pointer },
		},
		crypto_aead_chacha20poly1305_ietf_encrypt_detached = {
			returns = i32,
			args = { pointer, pointer, pointer, pointer, cSizeT, pointer, cSizeT, pointer, pointer, pointer },
		},
		crypto_aead_chacha20poly1305_ietf_decrypt_detached = {
			returns = i32,
			args = { pointer, pointer, pointer, cSizeT, pointer, pointer, cSizeT, pointer, pointer },
		},

		--  AEAD: XChaCha20-Poly1305

		crypto_aead_xchacha20poly1305_ietf_keygen = { returns = void, args = { pointer } },
		crypto_aead_xchacha20poly1305_ietf_encrypt = {
			returns = i32,
			args = { pointer, pointer, pointer, cSizeT, pointer, cSizeT, pointer, pointer, pointer },
		},
		crypto_aead_xchacha20poly1305_ietf_decrypt = {
			returns = i32,
			args = { pointer, pointer, pointer, pointer, cSizeT, pointer, cSizeT, pointer, pointer },
		},
		crypto_aead_xchacha20poly1305_ietf_encrypt_detached = {
			returns = i32,
			args = { pointer, pointer, pointer, pointer, cSizeT, pointer, cSizeT, pointer, pointer, pointer },
		},
		crypto_aead_xchacha20poly1305_ietf_decrypt_detached = {
			returns = i32,
			args = { pointer, pointer, pointer, cSizeT, pointer, pointer, cSizeT, pointer, pointer },
		},

		--  Secret-key authenticated encryption

		crypto_secretbox_keygen = { returns = void, args = { pointer } },
		crypto_secretbox_easy = { returns = i32, args = { pointer, pointer, cSizeT, pointer, pointer } },
		crypto_secretbox_open_easy = { returns = i32, args = { pointer, pointer, cSizeT, pointer, pointer } },
		crypto_secretbox_detached = { returns = i32, args = { pointer, pointer, pointer, cSizeT, pointer, pointer } },
		crypto_secretbox_open_detached = {
			returns = i32,
			args = { pointer, pointer, pointer, cSizeT, pointer, pointer },
		},

		--  Public-key authenticated encryption

		crypto_box_keypair = { returns = i32, args = { pointer, pointer } },
		crypto_box_beforenm = { returns = i32, args = { pointer, pointer, pointer } },
		crypto_box_easy = { returns = i32, args = { pointer, pointer, cSizeT, pointer, pointer, pointer } },
		crypto_box_open_easy = { returns = i32, args = { pointer, pointer, cSizeT, pointer, pointer, pointer } },
		crypto_box_detached = {
			returns = i32,
			args = { pointer, pointer, pointer, cSizeT, pointer, pointer, pointer },
		},
		crypto_box_open_detached = {
			returns = i32,
			args = { pointer, pointer, pointer, cSizeT, pointer, pointer, pointer },
		},
		crypto_box_easy_afternm = { returns = i32, args = { pointer, pointer, cSizeT, pointer, pointer } },
		crypto_box_open_easy_afternm = { returns = i32, args = { pointer, pointer, cSizeT, pointer, pointer } },

		--  Signatures (Ed25519)

		crypto_sign_keypair = { returns = i32, args = { pointer, pointer } },
		crypto_sign_ed25519_sk_to_pk = { returns = i32, args = { pointer, pointer } },
		crypto_sign_detached = { returns = i32, args = { pointer, pointer, pointer, cSizeT, pointer } },
		crypto_sign_verify_detached = { returns = i32, args = { pointer, pointer, cSizeT, pointer } },

		--  Generic hash (BLAKE2b)

		crypto_generichash_statebytes = { returns = cSizeT, args = {} },
		crypto_generichash = { returns = i32, args = { pointer, cSizeT, pointer, cSizeT, pointer, cSizeT } },
		crypto_generichash_init = { returns = i32, args = { pointer, pointer, cSizeT, cSizeT } },
		crypto_generichash_update = { returns = i32, args = { pointer, pointer, cSizeT } },
		crypto_generichash_final = { returns = i32, args = { pointer, pointer, cSizeT } },

		--  Hash (SHA-256 / SHA-512)

		crypto_hash_sha256 = { returns = i32, args = { pointer, pointer, cSizeT } },
		crypto_hash_sha512 = { returns = i32, args = { pointer, pointer, cSizeT } },

		--  Authentication (HMAC-SHA512256)

		crypto_auth_keygen = { returns = void, args = { pointer } },
		crypto_auth = { returns = i32, args = { pointer, pointer, cSizeT, pointer } },
		crypto_auth_verify = { returns = i32, args = { pointer, pointer, cSizeT, pointer } },

		--  Key derivation

		crypto_kdf_keygen = { returns = void, args = { pointer } },
		crypto_kdf_derive_from_key = { returns = i32, args = { pointer, cSizeT, u64, pointer, pointer } },

		--  Password hashing (Argon2id)

		crypto_pwhash = { returns = i32, args = { pointer, u64, pointer, u64, pointer, u64, cSizeT, i32 } },
		crypto_pwhash_str = { returns = i32, args = { pointer, pointer, u64, u64, cSizeT } },
		crypto_pwhash_str_verify = { returns = i32, args = { pointer, pointer, u64 } },
		crypto_pwhash_str_needs_rehash = { returns = i32, args = { pointer, u64, cSizeT } },

		--  Random bytes

		randombytes_buf = { returns = void, args = { pointer, cSizeT } },
		randombytes_uniform = { returns = u32, args = { u32 } },

		--  Utilities

		sodium_init = { returns = i32, args = {} },
		sodium_memcmp = { returns = i32, args = { pointer, pointer, cSizeT } },
		sodium_memzero = { returns = void, args = { pointer, cSizeT } },
		sodium_bin2hex = { returns = pointer, args = { pointer, cSizeT, pointer, cSizeT } },
		sodium_hex2bin = { returns = i32, args = { pointer, cSizeT, pointer, cSizeT, pointer, pointer, pointer } },
		sodium_base64_encoded_len = { returns = cSizeT, args = { cSizeT, i32 } },
		sodium_bin2base64 = { returns = pointer, args = { pointer, cSizeT, pointer, cSizeT, i32 } },
		sodium_base642bin = {
			returns = i32,
			args = { pointer, cSizeT, pointer, cSizeT, pointer, pointer, pointer, i32 },
		},
	}) :: any
) :: Lib

assert(lib.sodium_init() >= 0, "libsodium initialization failed")

return {
	lib = lib,

	aes256gcm = {
		KEY_BYTES = 32,
		NONCE_BYTES = 12,
		TAG_BYTES = 16,
	},

	chacha20poly1305 = {
		KEY_BYTES = 32,
		NONCE_BYTES = 12,
		TAG_BYTES = 16,
	},

	xchacha20poly1305 = {
		KEY_BYTES = 32,
		NONCE_BYTES = 24,
		TAG_BYTES = 16,
	},

	secretbox = {
		KEY_BYTES = 32,
		NONCE_BYTES = 24,
		MAC_BYTES = 16,
	},

	box = {
		PUBLIC_KEY_BYTES = 32,
		SECRET_KEY_BYTES = 32,
		NONCE_BYTES = 24,
		MAC_BYTES = 16,
		BEFORENM_BYTES = 32,
	},

	sign = {
		PUBLIC_KEY_BYTES = 32,
		SECRET_KEY_BYTES = 64,
		BYTES = 64,
	},

	generichash = {
		BYTES = 32,
		BYTES_MIN = 16,
		BYTES_MAX = 64,
		KEY_BYTES = 32,
		KEY_BYTES_MIN = 16,
		KEY_BYTES_MAX = 64,
	},

	hash = {
		SHA256_BYTES = 32,
		SHA512_BYTES = 64,
	},

	auth = {
		BYTES = 32,
		KEY_BYTES = 32,
	},

	kdf = {
		BYTES_MIN = 16,
		BYTES_MAX = 64,
		CONTEXT_BYTES = 8,
		KEY_BYTES = 32,
	},

	pwhash = {
		BYTES_MIN = 16,
		BYTES_MAX = 4294967295,
		SALT_BYTES = 16,
		STR_BYTES = 128,
		ALG_ARGON2ID13 = 2,
		OPSLIMIT_INTERACTIVE = 2,
		MEMLIMIT_INTERACTIVE = 67108864,
		OPSLIMIT_MODERATE = 3,
		MEMLIMIT_MODERATE = 268435456,
		OPSLIMIT_SENSITIVE = 4,
		MEMLIMIT_SENSITIVE = 1073741824,
	},

	base64 = {
		VARIANT_ORIGINAL = 1,
		VARIANT_ORIGINAL_NO_PADDING = 3,
		VARIANT_URLSAFE = 5,
		VARIANT_URLSAFE_NO_PADDING = 7,
	},
}
