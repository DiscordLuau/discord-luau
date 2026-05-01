--[=[
	@class Sodium

	FFI bindings for libsodium, providing authenticated encryption, hashing, signing, and key-derivation primitives.

	All functions use pre-built libsodium binaries bundled with this package - no system installation is required.
]=]

--[=[
	@prop sys Sodium.Sys
	@within Sodium
]=]

--[=[
	@prop aes256gcm Sodium.Aes256gcm
	@within Sodium
]=]

--[=[
	@prop chacha20poly1305 Sodium.Chacha20poly1305
	@within Sodium
]=]

--[=[
	@prop xchacha20poly1305 Sodium.Xchacha20poly1305
	@within Sodium
]=]

--[=[
	@prop secretbox Sodium.Secretbox
	@within Sodium
]=]

--[=[
	@prop box Sodium.Box
	@within Sodium
]=]

--[=[
	@prop sign Sodium.Sign
	@within Sodium
]=]

--[=[
	@prop generichash Sodium.Generichash
	@within Sodium
]=]

--[=[
	@prop hash Sodium.Hash
	@within Sodium
]=]

--[=[
	@prop auth Sodium.Auth
	@within Sodium
]=]

--[=[
	@prop kdf Sodium.Kdf
	@within Sodium
]=]

--[=[
	@prop pwhash Sodium.Pwhash
	@within Sodium
]=]

--[=[
	@prop randombytes Sodium.Randombytes
	@within Sodium
]=]

--[=[
	@prop utils Sodium.Utils
	@within Sodium
]=]

local Sys = require("@self/sys")
local Buffer = require("@self/buffer")
local Aes256gcm = require("@self/aead/aes256gcm")
local Chacha20poly1305 = require("@self/aead/chacha20poly1305")
local Xchacha20poly1305 = require("@self/aead/xchacha20poly1305")
local Secretbox = require("@self/secretbox")
local Box = require("@self/box")
local Sign = require("@self/sign")
local Generichash = require("@self/generichash")
local Hash = require("@self/hash")
local Auth = require("@self/auth")
local Kdf = require("@self/kdf")
local Pwhash = require("@self/pwhash")
local Randombytes = require("@self/randombytes")
local Utils = require("@self/utils")

-- Re-export shared types so consumers can annotate without importing buffer directly.
export type EncryptResult = Buffer.EncryptResult
export type SealResult = Buffer.SealResult
export type Keypair = Buffer.Keypair
export type Aead<T> = Buffer.Aead<T>

export type GenerichashState = Generichash.State

return {
	sys = Sys,

	aes256gcm = Aes256gcm,
	chacha20poly1305 = Chacha20poly1305,
	xchacha20poly1305 = Xchacha20poly1305,
	secretbox = Secretbox,
	box = Box,
	sign = Sign,
	generichash = Generichash,
	hash = Hash,
	auth = Auth,
	kdf = Kdf,
	pwhash = Pwhash,
	randombytes = Randombytes,
	utils = Utils,
}
