--# selene: allow(mixed_table)
--[[
	Vendored SHA-256, from kimpure/sha256 0.1.1 on pesde (https://github.com/yaeju1205/luau-sha256),
	itself a port of js-sha256. It is vendored because pesde does not apply a dependency's
	[patches] to the projects that install it, so every consumer of `binary` received the
	unpatched module and checksummed native libraries wrongly.

	Changes from upstream:
	- `update` hashes each byte of a string as-is instead of UTF-8 encoding it, so binary data
	  hashes correctly.
	- The unsigned conversion used by `hex` and `array` is `bit32.band(n, 0xFFFFFFFF)`.
	- `new` sets `lastByteIndex = 0`, so hashing an empty message no longer errors.

	Third-party code: kept close to upstream and exempt from this repository's style rules.

	Copyright (c) 2014-2024 Chen, Yi-Cyuan

	MIT License

	Permission is hereby granted, free of charge, to any person obtaining
	a copy of this software and associated documentation files (the
	"Software"), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

type Sha256Impl = {
	__index: Sha256Impl,
	new: (is224: boolean?, sharedMemory: boolean?) -> Sha256,
	update: (self: Sha256, message: string | { [any]: any }) -> Sha256,
	hash: (self: Sha256) -> (),
	finalize: (self: Sha256) -> (),
	array: (self: Sha256) -> { [number]: number },
	hex: (self: Sha256) -> string,
}

export type Sha256 = typeof(setmetatable(
	{} :: {
		blocks: { [number]: number },
		h0: number,
		h1: number,
		h2: number,
		h3: number,
		h4: number,
		h5: number,
		h6: number,
		h7: number,
		block: number,
		start: number,
		bytes: number,
		hBytes: number,
		finalized: boolean,
		hashed: boolean,
		first: boolean,
		is224: boolean?,
		lastByteIndex: number?,
	},
	{} :: Sha256Impl
))

local shift = { [0] = 24, 16, 8, 0 }
local extra = { [0] = -2147483648, 8388608, 32768, 128 }
local hexChars = { [0] = "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" }
local k = {
	[0] = 0x428a2f98,
	0x71374491,
	0xb5c0fbcf,
	0xe9b5dba5,
	0x3956c25b,
	0x59f111f1,
	0x923f82a4,
	0xab1c5ed5,
	0xd807aa98,
	0x12835b01,
	0x243185be,
	0x550c7dc3,
	0x72be5d74,
	0x80deb1fe,
	0x9bdc06a7,
	0xc19bf174,
	0xe49b69c1,
	0xefbe4786,
	0x0fc19dc6,
	0x240ca1cc,
	0x2de92c6f,
	0x4a7484aa,
	0x5cb0a9dc,
	0x76f988da,
	0x983e5152,
	0xa831c66d,
	0xb00327c8,
	0xbf597fc7,
	0xc6e00bf3,
	0xd5a79147,
	0x06ca6351,
	0x14292967,
	0x27b70a85,
	0x2e1b2138,
	0x4d2c6dfc,
	0x53380d13,
	0x650a7354,
	0x766a0abb,
	0x81c2c92e,
	0x92722c85,
	0xa2bfe8a1,
	0xa81a664b,
	0xc24b8b70,
	0xc76c51a3,
	0xd192e819,
	0xd6990624,
	0xf40e3585,
	0x106aa070,
	0x19a4c116,
	0x1e376c08,
	0x2748774c,
	0x34b0bcb5,
	0x391c0cb3,
	0x4ed8aa4a,
	0x5b9cca4f,
	0x682e6ff3,
	0x748f82ee,
	0x78a5636f,
	0x84c87814,
	0x8cc70208,
	0x90befffa,
	0xa4506ceb,
	0xbef9a3f7,
	0xc67178f2,
}

local bor = bit32.bor
local band = bit32.band
local rrotate = bit32.rrotate
local bxor = bit32.bxor
local lshift = bit32.lshift
local rshift = bit32.rshift
local bnot = bit32.bnot

local sha256 = {} :: Sha256Impl
sha256.__index = sha256

function sha256.new(is224, sharedMemory)
	local self = {}
	local blocks = {}

	if sharedMemory then
		for i = 0, 16 do
			blocks[i] = 0
			self.blocks = blocks
		end
	else
		self.blocks = { [0] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	end

	if is224 then
		self.h0 = 0xc1059ed8
		self.h1 = 0x367cd507
		self.h2 = 0x3070dd17
		self.h3 = 0xf70e5939
		self.h4 = 0xffc00b31
		self.h5 = 0x68581511
		self.h6 = 0x64f98fa7
		self.h7 = 0xbefa4fa4
	else
		self.h0 = 0x6a09e667
		self.h1 = 0xbb67ae85
		self.h2 = 0x3c6ef372
		self.h3 = 0xa54ff53a
		self.h4 = 0x510e527f
		self.h5 = 0x9b05688c
		self.h6 = 0x1f83d9ab
		self.h7 = 0x5be0cd19
	end

	self.block = 0
	self.start = 0
	self.bytes = 0
	self.hBytes = 0
	self.finalized = false
	self.hashed = false
	self.first = true
	self.is224 = is224
	self.lastByteIndex = 0

	return setmetatable(self, sha256)
end

function sha256.update(self, message)
	if self.finalized then
		return self
	end

	local code, i
	local index = 0
	local length = #message
	local blocks = self.blocks

	while index < length do
		if self.hashed then
			self.hashed = false
			blocks[0] = self.block
			self.block = 0
			for j = 1, 16 do
				blocks[j] = 0
			end
		end

		if typeof(message) ~= "string" then
			i = self.start + 1
			while index < length and i < 64 do
				blocks[rshift(i, 2)] = bor(blocks[rshift(i, 2)], lshift(message[index], shift[band(i, 3)]))
				i += 1
				index += 1
			end
		else
			i = self.start
			while index < length and i < 64 do
				code = message:byte(index + 1)
				blocks[rshift(i, 2)] = bor(blocks[rshift(i, 2)], lshift(code, shift[band(i, 3)]))
				i += 1
				index += 1
			end
		end

		self.lastByteIndex = i
		self.bytes += i - self.start

		if i >= 64 then
			self.block = blocks[16]
			self.start = i - 64
			self:hash()
			self.hashed = true
		else
			self.start = i
		end
	end

	if self.bytes > 4294967295 then
		self.hBytes += self.bytes / lshift(4294967296, 0)
		self.bytes = self.bytes % 4294967296
	end

	return self
end

function sha256.finalize(self)
	if self.finalized then
		return
	end

	self.finalized = true
	local blocks = self.blocks
	local i = self.lastByteIndex :: number

	blocks[16] = self.block
	blocks[rshift(i, 2)] = bor(blocks[rshift(i, 2)], extra[band(i, 3)])
	self.block = blocks[16]

	if i >= 56 then
		if not self.hashed then
			self:hash()
		end
		blocks[0] = self.block
		for j = 1, 16 do
			blocks[j] = 0
		end
	end

	blocks[14] = bor(lshift(self.hBytes, 3), rshift(self.bytes, 29))
	blocks[15] = lshift(self.bytes, 3)

	self:hash()
end

function sha256.hash(self)
	local function to_signed32(n)
		return bit32.band(n, 0xFFFFFFFF)
	end

	local a = self.h0
	local b = self.h1
	local c = self.h2
	local d = self.h3
	local e = self.h4
	local f = self.h5
	local g = self.h6
	local h = self.h7
	local blocks = self.blocks
	local s0, s1, maj, t1, t2, ch, ab, bc, cd, da

	for j = 16, 63 do
		t1 = blocks[j - 15]
		s0 = bxor(rrotate(t1, 7), rrotate(t1, 18), rshift(t1, 3))

		t1 = blocks[j - 2]
		s1 = bxor(rrotate(t1, 17), rrotate(t1, 19), rshift(t1, 10))
		blocks[j] = (blocks[j - 16] + s0 + blocks[j - 7] + s1) % 4294967296
	end

	bc = band(b, c)

	for j = 0, 63, 4 do
		if self.first then
			if self.is224 then
				ab = 300032
				t1 = blocks[0] - 1413257819
				h = to_signed32(t1 - 150054599)
				d = to_signed32(t1 + 24177077)
			else
				ab = 704751109
				t1 = blocks[0] - 210244248
				h = to_signed32(t1 - 1521486534)
				d = to_signed32(t1 + 143694565)
			end
			self.first = false
		else
			s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
			s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
			ab = band(a, b)
			maj = bxor(ab, band(a, c), bc)
			ch = bxor(band(e, f), band(bnot(e), g))
			t1 = to_signed32(h + s1 + ch + k[j] + blocks[j])
			t2 = s0 + maj
			h = to_signed32(d + t1)
			d = to_signed32(t1 + t2)
		end

		s0 = bxor(rrotate(d, 2), rrotate(d, 13), rrotate(d, 22))
		s1 = bxor(rrotate(h, 6), rrotate(h, 11), rrotate(h, 25))
		da = band(d, a)
		maj = bxor(da, band(d, b), ab)
		ch = bxor(band(h, e), band(bnot(h), f))
		t1 = to_signed32(g + s1 + ch + k[j + 1] + blocks[j + 1])
		t2 = s0 + maj
		g = to_signed32(c + t1)
		c = to_signed32(t1 + t2)

		s0 = bxor(rrotate(c, 2), rrotate(c, 13), rrotate(c, 22))
		s1 = bxor(rrotate(g, 6), rrotate(g, 11), rrotate(g, 25))
		cd = band(c, d)
		maj = bxor(cd, band(c, a), da)
		ch = bxor(band(g, h), band(bnot(g), e))
		t1 = to_signed32(f + s1 + ch + k[j + 2] + blocks[j + 2])
		t2 = s0 + maj
		f = to_signed32(b + t1)
		b = to_signed32(t1 + t2)

		s0 = bxor(rrotate(b, 2), rrotate(b, 13), rrotate(b, 22))
		s1 = bxor(rrotate(f, 6), rrotate(f, 11), rrotate(f, 25))
		bc = band(b, c)
		maj = bxor(bc, band(b, d), cd)
		ch = bxor(band(f, g), band(bnot(f), h))
		t1 = to_signed32(e + s1 + ch + k[j + 3] + blocks[j + 3])
		t2 = s0 + maj
		e = to_signed32(a + t1)
		a = to_signed32(t1 + t2)
	end

	self.h0 = to_signed32(self.h0 + a)
	self.h1 = to_signed32(self.h1 + b)
	self.h2 = to_signed32(self.h2 + c)
	self.h3 = to_signed32(self.h3 + d)
	self.h4 = to_signed32(self.h4 + e)
	self.h5 = to_signed32(self.h5 + f)
	self.h6 = to_signed32(self.h6 + g)
	self.h7 = to_signed32(self.h7 + h)
end

function sha256.array(self)
	self:finalize()

	local h0 = self.h0
	local h1 = self.h1
	local h2 = self.h2
	local h3 = self.h3
	local h4 = self.h4
	local h5 = self.h5
	local h6 = self.h6
	local h7 = self.h7

	local arr = {
		band(rshift(h0, 24), 0xFF),
		band(rshift(h0, 16), 0xFF),
		band(rshift(h0, 8), 0xFF),
		band(h0, 0xFF),
		band(rshift(h1, 24), 0xFF),
		band(rshift(h1, 16), 0xFF),
		band(rshift(h1, 8), 0xFF),
		band(h1, 0xFF),
		band(rshift(h2, 24), 0xFF),
		band(rshift(h2, 16), 0xFF),
		band(rshift(h2, 8), 0xFF),
		band(h2, 0xFF),
		band(rshift(h3, 24), 0xFF),
		band(rshift(h3, 16), 0xFF),
		band(rshift(h3, 8), 0xFF),
		band(h3, 0xFF),
		band(rshift(h4, 24), 0xFF),
		band(rshift(h4, 16), 0xFF),
		band(rshift(h4, 8), 0xFF),
		band(h4, 0xFF),
		band(rshift(h5, 24), 0xFF),
		band(rshift(h5, 16), 0xFF),
		band(rshift(h5, 8), 0xFF),
		band(h5, 0xFF),
		band(rshift(h6, 24), 0xFF),
		band(rshift(h6, 16), 0xFF),
		band(rshift(h6, 8), 0xFF),
		band(h6, 0xFF),
	}

	if not self.is224 then
		table.insert(arr, band(rshift(h7, 24), 0xFF))
		table.insert(arr, band(rshift(h7, 16), 0xFF))
		table.insert(arr, band(rshift(h7, 8), 0xFF))
		table.insert(arr, band(h7, 0xFF))
	end

	return arr
end

function sha256.hex(self)
	self:finalize()
	local h0 = self.h0
	local h1 = self.h1
	local h2 = self.h2
	local h3 = self.h3
	local h4 = self.h4
	local h5 = self.h5
	local h6 = self.h6
	local h7 = self.h7

	local hex = ""
	hex ..= hexChars[band(rshift(h0, 28), 0x0F)]
	hex ..= hexChars[band(rshift(h0, 24), 0x0F)]
	hex ..= hexChars[band(rshift(h0, 20), 0x0F)]
	hex ..= hexChars[band(rshift(h0, 16), 0x0F)]
	hex ..= hexChars[band(rshift(h0, 12), 0x0F)]
	hex ..= hexChars[band(rshift(h0, 8), 0x0F)]
	hex ..= hexChars[band(rshift(h0, 4), 0x0F)]
	hex ..= hexChars[band(h0, 0x0F)]

	hex ..= hexChars[band(rshift(h1, 28), 0x0F)]
	hex ..= hexChars[band(rshift(h1, 24), 0x0F)]
	hex ..= hexChars[band(rshift(h1, 20), 0x0F)]
	hex ..= hexChars[band(rshift(h1, 16), 0x0F)]
	hex ..= hexChars[band(rshift(h1, 12), 0x0F)]
	hex ..= hexChars[band(rshift(h1, 8), 0x0F)]
	hex ..= hexChars[band(rshift(h1, 4), 0x0F)]
	hex ..= hexChars[band(h1, 0x0F)]

	hex ..= hexChars[band(rshift(h2, 28), 0x0F)]
	hex ..= hexChars[band(rshift(h2, 24), 0x0F)]
	hex ..= hexChars[band(rshift(h2, 20), 0x0F)]
	hex ..= hexChars[band(rshift(h2, 16), 0x0F)]
	hex ..= hexChars[band(rshift(h2, 12), 0x0F)]
	hex ..= hexChars[band(rshift(h2, 8), 0x0F)]
	hex ..= hexChars[band(rshift(h2, 4), 0x0F)]
	hex ..= hexChars[band(h2, 0x0F)]

	hex ..= hexChars[band(rshift(h3, 28), 0x0F)]
	hex ..= hexChars[band(rshift(h3, 24), 0x0F)]
	hex ..= hexChars[band(rshift(h3, 20), 0x0F)]
	hex ..= hexChars[band(rshift(h3, 16), 0x0F)]
	hex ..= hexChars[band(rshift(h3, 12), 0x0F)]
	hex ..= hexChars[band(rshift(h3, 8), 0x0F)]
	hex ..= hexChars[band(rshift(h3, 4), 0x0F)]
	hex ..= hexChars[band(h3, 0x0F)]

	hex ..= hexChars[band(rshift(h4, 28), 0x0F)]
	hex ..= hexChars[band(rshift(h4, 24), 0x0F)]
	hex ..= hexChars[band(rshift(h4, 20), 0x0F)]
	hex ..= hexChars[band(rshift(h4, 16), 0x0F)]
	hex ..= hexChars[band(rshift(h4, 12), 0x0F)]
	hex ..= hexChars[band(rshift(h4, 8), 0x0F)]
	hex ..= hexChars[band(rshift(h4, 4), 0x0F)]
	hex ..= hexChars[band(h4, 0x0F)]

	hex ..= hexChars[band(rshift(h5, 28), 0x0F)]
	hex ..= hexChars[band(rshift(h5, 24), 0x0F)]
	hex ..= hexChars[band(rshift(h5, 20), 0x0F)]
	hex ..= hexChars[band(rshift(h5, 16), 0x0F)]
	hex ..= hexChars[band(rshift(h5, 12), 0x0F)]
	hex ..= hexChars[band(rshift(h5, 8), 0x0F)]
	hex ..= hexChars[band(rshift(h5, 4), 0x0F)]
	hex ..= hexChars[band(h5, 0x0F)]

	hex ..= hexChars[band(rshift(h6, 28), 0x0F)]
	hex ..= hexChars[band(rshift(h6, 24), 0x0F)]
	hex ..= hexChars[band(rshift(h6, 20), 0x0F)]
	hex ..= hexChars[band(rshift(h6, 16), 0x0F)]
	hex ..= hexChars[band(rshift(h6, 12), 0x0F)]
	hex ..= hexChars[band(rshift(h6, 8), 0x0F)]
	hex ..= hexChars[band(rshift(h6, 4), 0x0F)]
	hex ..= hexChars[band(h6, 0x0F)]

	if not self.is224 then
		hex ..= hexChars[band(rshift(h7, 28), 0x0F)]
		hex ..= hexChars[band(rshift(h7, 24), 0x0F)]
		hex ..= hexChars[band(rshift(h7, 20), 0x0F)]
		hex ..= hexChars[band(rshift(h7, 16), 0x0F)]
		hex ..= hexChars[band(rshift(h7, 12), 0x0F)]
		hex ..= hexChars[band(rshift(h7, 8), 0x0F)]
		hex ..= hexChars[band(rshift(h7, 4), 0x0F)]
		hex ..= hexChars[band(h7, 0x0F)]
	end

	return hex
end

return sha256
