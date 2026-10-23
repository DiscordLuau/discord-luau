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

	The next packet's nonce, sent big-endian as the packet's last four bytes. It starts at 0 with each session's new
	key, and `encryptRtp` raises instead of using `0xFFFFFFFF`.
]=]

local sodium = require("../luau_packages/sodium")
local dave = require("../luau_packages/dave")

local ENCRYPTION_MODE_AES256_GCM = "aead_aes256_gcm_rtpsize"

local RTP_HEADER_SIZE = 12
local DAVE_MAGIC_MARKER = 0xFAFA
local OPUS_SILENCE_FRAME = "\248\255\254"

local RtpCrypto = {}

RtpCrypto.Interface = {}
RtpCrypto.Prototype = {}

--[=[
	@within Voice.RtpCrypto

	Encrypts an RTP packet with the session cipher, and returns it with whether its Opus payload was replaced by
	silence. Under DAVE (`mediaProtocolVersion` above 0) the payload is DAVE-encrypted first when `mediaReady` and an
	encryptor are both there; otherwise the 3-byte Opus silence frame `F8 FF FE` goes in its place, which libdave
	documents as the substitute while no key is active, so audio never leaves without DAVE. A payload that is exactly
	that silence frame is never DAVE-encrypted, as discord.js and DAVEY send it, and libdave's decryptors pass it
	through. Without DAVE the payload goes as it is. Raises `RTP nonce exhausted; the session needs a new key`, before
	touching the encryptor, once the nonce counter reaches `0xFFFFFFFF`.
]=]
function RtpCrypto.Prototype.encryptRtp(
	self: RtpCrypto,
	rtpPacket: buffer,
	daveEncryptor: dave.Encryptor?,
	ssrc: number,
	mediaProtocolVersion: number?,
	mediaReady: boolean?
): (buffer, boolean)
	local secretKey = self.secretKey
	local mode = self.encryptionMode
	local nonceCounter = self.rtpNonceCounter
	local daveMedia = if mediaProtocolVersion then mediaProtocolVersion > 0 else false
	local substitutesSilence = daveMedia and not (mediaReady and daveEncryptor)
	local carriesSilence = buffer.len(rtpPacket) == RTP_HEADER_SIZE + #OPUS_SILENCE_FRAME
		and buffer.readstring(rtpPacket, RTP_HEADER_SIZE, #OPUS_SILENCE_FRAME) == OPUS_SILENCE_FRAME
	local header = buffer.create(RTP_HEADER_SIZE)
	local payload = buffer.create(buffer.len(rtpPacket) - RTP_HEADER_SIZE)
	local nonceSuffix = buffer.create(4)
	local encrypted

	assert(secretKey, "cannot encrypt RTP: no secret key")
	assert(mode, "cannot encrypt RTP: no encryption mode")
	assert(nonceCounter < 0xFFFFFFFF, "RTP nonce exhausted; the session needs a new key")

	buffer.copy(header, 0, rtpPacket, 0, RTP_HEADER_SIZE)
	buffer.copy(payload, 0, rtpPacket, RTP_HEADER_SIZE, buffer.len(payload))

	if substitutesSilence then
		payload = buffer.fromstring(OPUS_SILENCE_FRAME)
	elseif daveMedia and daveEncryptor and not carriesSilence then
		payload = daveEncryptor:encrypt(dave.sys.mediaType.audio, ssrc, payload)
	end

	self.rtpNonceCounter = nonceCounter + 1

	buffer.writeu32(nonceSuffix, 0, bit32.byteswap(nonceCounter))

	if mode == ENCRYPTION_MODE_AES256_GCM then
		local nonce = buffer.create(12)
		buffer.copy(nonce, 0, nonceSuffix, 0, 4)
		encrypted = sodium.aes256gcm.encrypt(payload, secretKey, nonce, header)
	else
		local nonce = buffer.create(24)
		buffer.copy(nonce, 0, nonceSuffix, 0, 4)
		encrypted = sodium.xchacha20poly1305.encrypt(payload, secretKey, nonce, header)
	end

	local payloadLength = buffer.len(payload)
	local tagLength = buffer.len(encrypted.tag)
	local result = buffer.create(RTP_HEADER_SIZE + payloadLength + tagLength + 4)

	buffer.copy(result, 0, header, 0, RTP_HEADER_SIZE)
	buffer.copy(result, RTP_HEADER_SIZE, encrypted.cipher, 0, payloadLength)
	buffer.copy(result, RTP_HEADER_SIZE + payloadLength, encrypted.tag, 0, tagLength)
	buffer.copy(result, RTP_HEADER_SIZE + payloadLength + tagLength, nonceSuffix, 0, 4)

	return result, substitutesSilence
end

--[=[
	@within Voice.RtpCrypto

	Decrypts an RTP packet using the session cipher. Handles RTP header extensions and padding, then
	optionally DAVE-decrypts the Opus payload using the per-user decryptor for the sender's SSRC. The packet it returns
	has a plain 12-byte header: the CSRC list and the extension are dropped, so the first byte keeps only the version.
	Returns nil and the reason for a packet it drops: one too short for its header, tag and nonce, one whose header
	extension claims more than the plaintext holds, a DAVE frame from a sender with no decryptor yet, which happens
	until their keys arrive, and, while media is under DAVE (`mediaProtocolVersion` above 0) and no move to version 0
	is pending, any other frame from such a sender except the 3-byte Opus silence frame.
]=]
function RtpCrypto.Prototype.decryptRtp(
	self: RtpCrypto,
	rtpPacket: buffer,
	ssrcToUserId: { [number]: string },
	daveDecryptors: { [string]: dave.Decryptor },
	mediaProtocolVersion: number?,
	downgradePending: boolean?
): (buffer?, string?)
	local secretKey = self.secretKey
	local mode = self.encryptionMode
	local requiresDave = if mediaProtocolVersion then mediaProtocolVersion > 0 and not downgradePending else false
	local tagBytes = 16
	local nonceSuffixBytes = 4
	local extensionBodySize = 0
	local plaintext
	local packetLength = buffer.len(rtpPacket)

	if packetLength < RTP_HEADER_SIZE then
		return nil, `it is {packetLength} bytes, shorter than the {RTP_HEADER_SIZE}-byte RTP header`
	end

	local firstByte = buffer.readu8(rtpPacket, 0)
	local hasPadding = bit32.band(firstByte, 0x20) ~= 0
	local hasExtension = bit32.band(firstByte, 0x10) ~= 0
	local csrcCount = bit32.band(firstByte, 0x0F)
	local extensionOffset = RTP_HEADER_SIZE + csrcCount * 4
	local cipherStart = extensionOffset + (if hasExtension then 4 else 0)
	local cipherLength = packetLength - cipherStart - tagBytes - nonceSuffixBytes
	local senderSsrc = bit32.bor(
		bit32.lshift(buffer.readu8(rtpPacket, 8), 24),
		bit32.lshift(buffer.readu8(rtpPacket, 9), 16),
		bit32.lshift(buffer.readu8(rtpPacket, 10), 8),
		buffer.readu8(rtpPacket, 11)
	)
	local senderUserId = ssrcToUserId[senderSsrc]
	local decryptor = if senderUserId then daveDecryptors[senderUserId] else nil

	assert(secretKey, "cannot decrypt RTP: no secret key")
	assert(mode, "cannot decrypt RTP: no encryption mode")

	if cipherLength < 0 then
		return nil, `it is {packetLength} bytes, too short for its {cipherStart}-byte header, tag and nonce`
	end

	local cipher = buffer.create(cipherLength)
	local tag = buffer.create(tagBytes)
	local aad = buffer.create(cipherStart)

	buffer.copy(cipher, 0, rtpPacket, cipherStart, cipherLength)
	buffer.copy(tag, 0, rtpPacket, cipherStart + cipherLength, tagBytes)
	buffer.copy(aad, 0, rtpPacket, 0, cipherStart)

	if hasExtension then
		local extensionWords = bit32.bor(
			bit32.lshift(buffer.readu8(rtpPacket, extensionOffset + 2), 8),
			buffer.readu8(rtpPacket, extensionOffset + 3)
		)

		extensionBodySize = extensionWords * 4
	end

	if mode == ENCRYPTION_MODE_AES256_GCM then
		local nonce = buffer.create(12)
		buffer.copy(nonce, 0, rtpPacket, packetLength - nonceSuffixBytes, nonceSuffixBytes)
		plaintext = sodium.aes256gcm.decrypt(cipher, tag, secretKey, nonce, aad)
	else
		local nonce = buffer.create(24)
		buffer.copy(nonce, 0, rtpPacket, packetLength - nonceSuffixBytes, nonceSuffixBytes)
		plaintext = sodium.xchacha20poly1305.decrypt(cipher, tag, secretKey, nonce, aad)
	end

	local opusLength = buffer.len(plaintext) - extensionBodySize

	if opusLength < 0 then
		return nil, `its header extension claims {extensionBodySize} bytes of a {buffer.len(plaintext)}-byte payload`
	end

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
	elseif opusLength >= 2 and buffer.readu16(opusPayload, opusLength - 2) == DAVE_MAGIC_MARKER then
		return nil, `it is a DAVE frame from ssrc {senderSsrc}, who has no DAVE decryptor yet`
	elseif requiresDave and not decryptor and buffer.tostring(opusPayload) ~= OPUS_SILENCE_FRAME then
		return nil, `it is a plain frame from ssrc {senderSsrc}, who has no DAVE decryptor, while media is under DAVE`
	end

	local result = buffer.create(RTP_HEADER_SIZE + opusLength)

	buffer.copy(result, 0, rtpPacket, 0, RTP_HEADER_SIZE)
	buffer.writeu8(result, 0, bit32.band(firstByte, 0xC0))
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
