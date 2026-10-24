local frktest = require("../../../luau_packages/frktest")
local dave = require("../luau_packages/dave")
local sodium = require("../luau_packages/sodium")
local stdPolyfills = require("../luau_packages/std_polyfills")

local voice = require("../src")

local SENDER_SSRC = 4321
local RTP_HEADER_SIZE = 12
local SECRET_KEY_SIZE = 32
local NONCE_SIZE = 24
local NONCE_SUFFIX_SIZE = 4
local DAVE_MAGIC_MARKER = "\250\250"
local OPUS_FRAME = "ten bytes!"
local OPUS_SILENCE = "\248\255\254"

local test = frktest.test
local check = frktest.assert.check

if not stdPolyfills.runtime.capabilities().ffi then
	assert(
		not stdPolyfills.process.getEnv().DISCORD_LUAU_REQUIRE_FFI,
		"DISCORD_LUAU_REQUIRE_FFI is set but this runtime has no FFI"
	)

	return function()
		test.skip.suite("Voice RTP", function() end)
	end
end

local function plainPacket(payload: string): buffer
	local rtpPacket = buffer.create(RTP_HEADER_SIZE + #payload)

	buffer.writeu8(rtpPacket, 0, 0x80)
	buffer.writeu8(rtpPacket, 1, 0x78)
	buffer.writeu32(rtpPacket, 8, bit32.byteswap(SENDER_SSRC))
	buffer.writestring(rtpPacket, RTP_HEADER_SIZE, payload)

	return rtpPacket
end

local function sealedPacket(crypto: voice.RtpCrypto, payload: string): buffer
	return (crypto:encryptRtp(plainPacket(payload), nil, SENDER_SSRC))
end

local function payloadOf(rtpPacket: buffer?): string?
	return if rtpPacket
		then buffer.readstring(rtpPacket, RTP_HEADER_SIZE, buffer.len(rtpPacket) - RTP_HEADER_SIZE)
		else nil
end

local function newCrypto(): voice.RtpCrypto
	local crypto = voice.rtp.new()

	crypto.secretKey = buffer.create(SECRET_KEY_SIZE)
	crypto.encryptionMode = "aead_xchacha20_poly1305_rtpsize"

	return crypto
end

local function handSealed(header: buffer, payload: string): buffer
	local headerLength = buffer.len(header)
	local sealed = sodium.xchacha20poly1305.encrypt(
		buffer.fromstring(payload),
		buffer.create(SECRET_KEY_SIZE),
		buffer.create(NONCE_SIZE),
		header
	)
	local cipherLength = buffer.len(sealed.cipher)
	local tagLength = buffer.len(sealed.tag)
	local packet = buffer.create(headerLength + cipherLength + tagLength + NONCE_SUFFIX_SIZE)

	buffer.copy(packet, 0, header)
	buffer.copy(packet, headerLength, sealed.cipher)
	buffer.copy(packet, headerLength + cipherLength, sealed.tag)

	return packet
end

local function nonceOf(packet: buffer): number
	return bit32.byteswap(buffer.readu32(packet, buffer.len(packet) - NONCE_SUFFIX_SIZE))
end

local function countingEncryptor(): any
	local encryptor: any = { encryptCalls = 0 }

	function encryptor.encrypt(_, _mediaType: number, _ssrc: number, frame: buffer)
		encryptor.encryptCalls += 1

		return buffer.fromstring(`dave:{buffer.tostring(frame)}`)
	end

	return encryptor
end

return function()
	test.suite("Voice RTP", function()
		test.case("drops a DAVE frame from a sender with no decryptor", function()
			local crypto = newCrypto()
			local packet = sealedPacket(crypto, "ciphertext" .. DAVE_MAGIC_MARKER)

			check.equal(crypto:decryptRtp(packet, {}, {}), nil)
		end)

		test.case("passes plain Opus through from a sender with no decryptor", function()
			local crypto = newCrypto()
			local packet = sealedPacket(crypto, "plain opus")
			local decrypted = crypto:decryptRtp(packet, {}, {})

			check.not_nil(decrypted)
			check.equal(buffer.readstring(decrypted :: buffer, RTP_HEADER_SIZE, #"plain opus"), "plain opus")
		end)

		test.case("under DAVE before media is ready, Opus silence goes out, with or without an encryptor", function()
			local crypto = newCrypto()
			local encryptor = dave.Encryptor.new()
			local withEncryptor, encryptorSilenced =
				crypto:encryptRtp(plainPacket(OPUS_FRAME), encryptor, SENDER_SSRC, 1, false)
			local withoutEncryptor, nilSilenced = crypto:encryptRtp(plainPacket(OPUS_FRAME), nil, SENDER_SSRC, 1, false)
			local openedWithEncryptor = crypto:decryptRtp(withEncryptor, {}, {})
			local openedWithoutEncryptor = crypto:decryptRtp(withoutEncryptor, {}, {})

			encryptor:destroy()

			check.equal(payloadOf(openedWithEncryptor), OPUS_SILENCE)
			check.equal(payloadOf(openedWithoutEncryptor), OPUS_SILENCE)
			check.is_true(encryptorSilenced)
			check.is_true(nilSilenced)
		end)

		test.case("media ready under DAVE goes through the encryptor, and version 0 goes out as it is", function()
			local crypto = newCrypto()
			local encryptor: any = {
				hasKeyRatchet = function()
					return true
				end,
				encrypt = function(_, _mediaType: number, _ssrc: number, frame: buffer)
					return buffer.fromstring(`dave:{buffer.tostring(frame)}`)
				end,
			}
			local daveSealed = crypto:encryptRtp(plainPacket(OPUS_FRAME), encryptor, SENDER_SSRC, 1, true)
			local plainSealed = crypto:encryptRtp(plainPacket(OPUS_FRAME), encryptor, SENDER_SSRC, 0, true)
			local daveOpened = crypto:decryptRtp(daveSealed, {}, {})
			local plainOpened = crypto:decryptRtp(plainSealed, {}, {})

			check.equal(payloadOf(daveOpened), `dave:{OPUS_FRAME}`)
			check.equal(payloadOf(plainOpened), OPUS_FRAME)
		end)

		test.case("under DAVE, a plain frame from a sender with no decryptor is dropped but silence passes", function()
			local crypto = newCrypto()
			local plain = crypto:decryptRtp(sealedPacket(crypto, OPUS_FRAME), {}, {}, 1, false)
			local silence = crypto:decryptRtp(sealedPacket(crypto, OPUS_SILENCE), {}, {}, 1, false)

			check.equal(plain, nil)
			check.equal(payloadOf(silence), OPUS_SILENCE)
		end)

		test.case("under DAVE, an empty frame from a sender with a decryptor is not dropped as plain", function()
			local crypto = newCrypto()
			local decryptor: any = {
				decrypt = function(_, _mediaType: number, frame: buffer)
					return frame
				end,
			}
			local opened, dropReason = crypto:decryptRtp(
				sealedPacket(crypto, ""),
				{ [SENDER_SSRC] = "5" },
				{ ["5"] = decryptor },
				1,
				false
			)

			check.equal(payloadOf(opened), "")
			check.equal(dropReason, nil)
		end)

		test.case("under DAVE, a plain frame passes while a move to version 0 is pending", function()
			local crypto = newCrypto()
			local passed = crypto:decryptRtp(sealedPacket(crypto, OPUS_FRAME), {}, {}, 1, true)

			check.equal(payloadOf(passed), OPUS_FRAME)
		end)

		test.case("the nonce goes on the wire big-endian, so the first two packets carry 0 and 1", function()
			local crypto = newCrypto()
			local first = crypto:encryptRtp(plainPacket(OPUS_FRAME), nil, SENDER_SSRC)
			local second = crypto:encryptRtp(plainPacket(OPUS_FRAME), nil, SENDER_SSRC)

			check.equal(nonceOf(first), 0)
			check.equal(nonceOf(second), 1)
		end)

		test.case("an exhausted nonce raises before the DAVE encryptor runs, and is not used", function()
			local crypto = newCrypto()
			local encryptor = countingEncryptor()

			crypto.rtpNonceCounter = 0xFFFFFFFF

			local encrypted, failure = pcall(function()
				crypto:encryptRtp(plainPacket(OPUS_FRAME), encryptor, SENDER_SSRC, 1, true)
			end)

			check.is_false(encrypted)
			check.not_nil((string.find(tostring(failure), "RTP nonce exhausted; the session needs a new key", 1, true)))
			check.equal(encryptor.encryptCalls, 0)
			check.equal(crypto.rtpNonceCounter, 0xFFFFFFFF)
		end)

		test.case("a packet with CSRCs decrypts to a plain 12-byte header with no CSRC count", function()
			local crypto = newCrypto()
			local header = buffer.create(RTP_HEADER_SIZE + 8)

			buffer.writeu8(header, 0, 0x82)
			buffer.writeu8(header, 1, 0x78)
			buffer.writeu32(header, 8, bit32.byteswap(SENDER_SSRC))

			local opened = crypto:decryptRtp(handSealed(header, OPUS_FRAME), {}, {})

			check.equal(if opened then buffer.readu8(opened, 0) else nil, 0x80)
			check.equal(payloadOf(opened), OPUS_FRAME)
		end)

		test.case("under DAVE and media-ready, the silence frame goes out without the encryptor", function()
			local crypto = newCrypto()
			local encryptor = countingEncryptor()
			local sealed, silenced = crypto:encryptRtp(plainPacket(OPUS_SILENCE), encryptor, SENDER_SSRC, 1, true)
			local opened = crypto:decryptRtp(sealed, {}, {})

			check.equal(payloadOf(opened), OPUS_SILENCE)
			check.equal(encryptor.encryptCalls, 0)
			check.is_false(silenced)
		end)

		test.case("under DAVE and media-ready, silence plus one byte is still DAVE-encrypted", function()
			local crypto = newCrypto()
			local encryptor = countingEncryptor()
			local payload = `{OPUS_SILENCE}\0`
			local sealed = crypto:encryptRtp(plainPacket(payload), encryptor, SENDER_SSRC, 1, true)
			local opened = crypto:decryptRtp(sealed, {}, {})

			check.equal(payloadOf(opened), `dave:{payload}`)
			check.equal(encryptor.encryptCalls, 1)
		end)

		test.case("under DAVE and media-ready, a 3-byte payload that is not silence is DAVE-encrypted", function()
			local crypto = newCrypto()
			local encryptor = countingEncryptor()
			local payload = "\16\0\0"
			local sealed = crypto:encryptRtp(plainPacket(payload), encryptor, SENDER_SSRC, 1, true)
			local opened = crypto:decryptRtp(sealed, {}, {})

			check.equal(payloadOf(opened), `dave:{payload}`)
			check.equal(encryptor.encryptCalls, 1)
		end)

		test.case("an extension that claims more than the packet holds is dropped with a reason", function()
			local crypto = newCrypto()
			local header = buffer.create(RTP_HEADER_SIZE + 4)

			buffer.writeu8(header, 0, 0x90)
			buffer.writeu8(header, 1, 0x78)
			buffer.writeu32(header, 8, bit32.byteswap(SENDER_SSRC))
			buffer.writeu8(header, RTP_HEADER_SIZE + 3, 16)

			local opened, dropReason = crypto:decryptRtp(handSealed(header, OPUS_SILENCE), {}, {})

			check.equal(opened, nil)
			check.not_nil(dropReason and string.find(dropReason, "header extension", 1, true))
		end)

		test.case("an empty packet is dropped with a reason instead of raising", function()
			local crypto = newCrypto()
			local ok, opened, dropReason = pcall(crypto.decryptRtp, crypto, buffer.create(0), {}, {})

			check.is_true(ok)
			check.equal(opened, nil)
			check.not_nil(dropReason and string.find(dropReason, "RTP header", 1, true))
		end)

		test.case("a packet one byte short of the RTP header is dropped with a reason instead of raising", function()
			local crypto = newCrypto()
			local ok, opened, dropReason = pcall(crypto.decryptRtp, crypto, buffer.create(RTP_HEADER_SIZE - 1), {}, {})

			check.is_true(ok)
			check.equal(opened, nil)
			check.not_nil(dropReason and string.find(dropReason, "RTP header", 1, true))
		end)
	end)
end
