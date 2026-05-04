--[=[
	@class Voice.RtpCrypto
	@__index Prototype

	Handles RTP packet encryption and decryption for a voice connection.
	Owns the session secret key, encryption mode selection, and all sequence, timestamp, and nonce counters.
]=]

--[=[
	@prop secretKey buffer?
	@within Voice.RtpCrypto
]=]

--[=[
	@prop encryptionMode string?
	@within Voice.RtpCrypto
]=]

--[=[
	@prop rtpSequence number
	@within Voice.RtpCrypto
]=]

--[=[
	@prop rtpTimestamp number
	@within Voice.RtpCrypto
]=]

--[=[
	@prop rtpNonceCounter number
	@within Voice.RtpCrypto
]=]

local sodium = require("../luau_packages/sodium")
local dave = require("../luau_packages/dave")

local ENCRYPTION_MODE_AES256_GCM = "aead_aes256_gcm_rtpsize"
local ENCRYPTION_MODE_XCHACHA20 = "aead_xchacha20_poly1305_rtpsize"

local RTP_HEADER_SIZE = 12

local RtpCrypto = {}

RtpCrypto.Interface = {}
RtpCrypto.Prototype = {}

--[=[
	@within Voice.RtpCrypto

	Encrypts an RTP packet. If a DAVE encryptor with an active key ratchet is provided, the Opus payload
	is DAVE-encrypted before the session cipher is applied.
]=]
function RtpCrypto.Prototype.encryptRtp(
	self: RtpCrypto,
	rtpPacket: buffer,
	daveEncryptor: dave.Encryptor?,
	ssrc: number
): buffer
	local secretKey = self.secretKey
	local mode = self.encryptionMode

	assert(secretKey, "cannot encrypt RTP: no secret key")
	assert(mode, "cannot encrypt RTP: no encryption mode")

	local header = buffer.create(RTP_HEADER_SIZE)
	buffer.copy(header, 0, rtpPacket, 0, RTP_HEADER_SIZE)

	local payload = buffer.create(buffer.len(rtpPacket) - RTP_HEADER_SIZE)
	buffer.copy(payload, 0, rtpPacket, RTP_HEADER_SIZE, buffer.len(payload))

	if daveEncryptor and daveEncryptor:hasKeyRatchet() then
		payload = daveEncryptor:encrypt(dave.sys.mediaType.audio, ssrc, payload)
	end

	local payloadLength = buffer.len(payload)
	local nonceCounter = self.rtpNonceCounter
	self.rtpNonceCounter = nonceCounter + 1

	local nonceSuffix = buffer.create(4)
	buffer.writeu8(nonceSuffix, 0, bit32.band(nonceCounter, 0xFF))
	buffer.writeu8(nonceSuffix, 1, bit32.rshift(bit32.band(nonceCounter, 0xFF00), 8))
	buffer.writeu8(nonceSuffix, 2, bit32.rshift(bit32.band(nonceCounter, 0xFF0000), 16))
	buffer.writeu8(nonceSuffix, 3, bit32.rshift(bit32.band(nonceCounter, 0xFF000000), 24))

	local encrypted

	if mode == ENCRYPTION_MODE_AES256_GCM then
		local nonce = buffer.create(12)
		buffer.copy(nonce, 0, nonceSuffix, 0, 4)
		encrypted = sodium.aes256gcm.encrypt(payload, secretKey, nonce, header)
	else
		local nonce = buffer.create(24)
		buffer.copy(nonce, 0, nonceSuffix, 0, 4)
		encrypted = sodium.xchacha20poly1305.encrypt(payload, secretKey, nonce, header)
	end

	local tagLength = buffer.len(encrypted.tag)
	local result = buffer.create(RTP_HEADER_SIZE + payloadLength + tagLength + 4)

	buffer.copy(result, 0, header, 0, RTP_HEADER_SIZE)
	buffer.copy(result, RTP_HEADER_SIZE, encrypted.cipher, 0, payloadLength)
	buffer.copy(result, RTP_HEADER_SIZE + payloadLength, encrypted.tag, 0, tagLength)
	buffer.copy(result, RTP_HEADER_SIZE + payloadLength + tagLength, nonceSuffix, 0, 4)

	return result
end

--[=[
	@within Voice.RtpCrypto

	Decrypts an RTP packet using the session cipher. Handles RTP header extensions and padding, then
	optionally DAVE-decrypts the Opus payload using the per-user decryptor for the sender's SSRC.
]=]
function RtpCrypto.Prototype.decryptRtp(
	self: RtpCrypto,
	rtpPacket: buffer,
	ssrcToUserId: { [number]: string },
	daveDecryptors: { [string]: dave.Decryptor }
): buffer
	local secretKey = self.secretKey
	local mode = self.encryptionMode

	assert(secretKey, "cannot decrypt RTP: no secret key")
	assert(mode, "cannot decrypt RTP: no encryption mode")

	local tagBytes = 16
	local nonceSuffixBytes = 4
	local packetLength = buffer.len(rtpPacket)

	local firstByte = buffer.readu8(rtpPacket, 0)
	local hasPadding = bit32.band(firstByte, 0x20) ~= 0
	local hasExtension = bit32.band(firstByte, 0x10) ~= 0
	local csrcCount = bit32.band(firstByte, 0x0F)
	local csrcSize = csrcCount * 4
	local extensionOffset = RTP_HEADER_SIZE + csrcSize

	local extensionBodySize = 0

	if hasExtension then
		local extensionWords = bit32.bor(
			bit32.lshift(buffer.readu8(rtpPacket, extensionOffset + 2), 8),
			buffer.readu8(rtpPacket, extensionOffset + 3)
		)
		extensionBodySize = extensionWords * 4
	end

	local cipherStart = extensionOffset + (if hasExtension then 4 else 0)
	local cipherLength = packetLength - cipherStart - tagBytes - nonceSuffixBytes

	local cipher = buffer.create(cipherLength)
	buffer.copy(cipher, 0, rtpPacket, cipherStart, cipherLength)

	local tag = buffer.create(tagBytes)
	buffer.copy(tag, 0, rtpPacket, cipherStart + cipherLength, tagBytes)

	local aad = buffer.create(cipherStart)
	buffer.copy(aad, 0, rtpPacket, 0, cipherStart)

	local plaintext

	if mode == ENCRYPTION_MODE_AES256_GCM then
		local nonce = buffer.create(12)
		buffer.copy(nonce, 0, rtpPacket, packetLength - nonceSuffixBytes, nonceSuffixBytes)
		plaintext = sodium.aes256gcm.decrypt(cipher, tag, secretKey, nonce, aad)
	else
		local nonce = buffer.create(24)
		buffer.copy(nonce, 0, rtpPacket, packetLength - nonceSuffixBytes, nonceSuffixBytes)
		plaintext = sodium.xchacha20poly1305.decrypt(cipher, tag, secretKey, nonce, aad)
	end

	local senderSsrc = bit32.bor(
		bit32.lshift(buffer.readu8(rtpPacket, 8), 24),
		bit32.lshift(buffer.readu8(rtpPacket, 9), 16),
		bit32.lshift(buffer.readu8(rtpPacket, 10), 8),
		buffer.readu8(rtpPacket, 11)
	)

	local senderUserId = ssrcToUserId[senderSsrc]
	local decryptor = if senderUserId then daveDecryptors[senderUserId] else nil

	local opusLength = buffer.len(plaintext) - extensionBodySize

	if hasPadding and opusLength > 0 then
		local paddingByteCount = buffer.readu8(plaintext, buffer.len(plaintext) - 1)

		if paddingByteCount > 0 and paddingByteCount <= opusLength then
			opusLength -= paddingByteCount
		end
	end

	local opusPayload = buffer.create(opusLength)
	buffer.copy(opusPayload, 0, plaintext, extensionBodySize, opusLength)

	if decryptor and opusLength > 0 then
		opusPayload = decryptor:decrypt(dave.sys.mediaType.audio, opusPayload)
		opusLength = buffer.len(opusPayload)
	end

	local result = buffer.create(RTP_HEADER_SIZE + opusLength)
	buffer.copy(result, 0, rtpPacket, 0, RTP_HEADER_SIZE)
	buffer.writeu8(result, 0, bit32.band(firstByte, 0xCF))
	buffer.copy(result, RTP_HEADER_SIZE, opusPayload, 0, opusLength)

	return result
end

--[=[
	@within Voice.RtpCrypto

	Clears the secret key and encryption mode, and resets all sequence, timestamp, and nonce counters to zero.
]=]
function RtpCrypto.Prototype.reset(self: RtpCrypto)
	self.secretKey = nil
	self.encryptionMode = nil
	self.rtpSequence = 0
	self.rtpTimestamp = 0
	self.rtpNonceCounter = 0
end

--[=[
	@within Voice.RtpCrypto

	Responsible for constructing this class.
]=]
function RtpCrypto.Interface.new(): RtpCrypto
	return setmetatable(
		{
			rtpSequence = 0,
			rtpTimestamp = 0,
			rtpNonceCounter = 0,
		} :: RtpCrypto,
		{ __index = RtpCrypto.Prototype }
	)
end

export type RtpCrypto = typeof(RtpCrypto.Prototype) & {
	secretKey: buffer?,
	encryptionMode: string?,
	rtpSequence: number,
	rtpTimestamp: number,
	rtpNonceCounter: number,
}

return RtpCrypto.Interface
