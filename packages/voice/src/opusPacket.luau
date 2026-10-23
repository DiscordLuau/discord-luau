--[=[
	@class Voice.OpusPacket

	Reads the TOC byte that starts every Opus packet (RFC 6716 section 3.1) to tell how much audio the packet holds.
]=]

local MAX_PACKET_SAMPLES = 5760
local SILK_FRAME_SAMPLES = { 480, 960, 1920, 2880 }
local HYBRID_FRAME_SAMPLES = { 480, 960 }
local CELT_FRAME_SAMPLES = { 120, 240, 480, 960 }

--[=[
	@within Voice.OpusPacket

	Returns how many 48 kHz samples (per channel) of audio `packet` holds: its frame count times its frame size, both
	read from the TOC byte. 960 is 20 ms. Raises for an empty packet, a code 3 packet without its frame count byte or
	with 0 frames, and a packet longer than 120 ms (5760 samples).
]=]
local function opusSamples(packet: buffer): number
	local packetLength = buffer.len(packet)
	local toc = if packetLength > 0 then buffer.readu8(packet, 0) else 0
	local config = bit32.rshift(toc, 3)
	local frameCountCode = bit32.band(toc, 0x03)
	local frameSamples = if config < 12
		then SILK_FRAME_SAMPLES[config % 4 + 1]
		elseif config < 16 then HYBRID_FRAME_SAMPLES[config % 2 + 1]
		else CELT_FRAME_SAMPLES[config % 4 + 1]
	local frameCount = if frameCountCode == 0
		then 1
		elseif frameCountCode < 3 then 2
		elseif packetLength >= 2 then bit32.band(buffer.readu8(packet, 1), 0x3F)
		else 0
	local samples = frameCount * frameSamples

	if packetLength == 0 then
		error("invalid Opus packet: it is empty", 0)
	end

	if frameCountCode == 3 and packetLength < 2 then
		error("invalid Opus packet: code 3 without its frame count byte", 0)
	end

	if frameCount == 0 then
		error("invalid Opus packet: code 3 with 0 frames", 0)
	end

	if samples > MAX_PACKET_SAMPLES then
		error(`invalid Opus packet: {samples} samples is longer than 120 ms`, 0)
	end

	return samples
end

return {
	opusSamples = opusSamples,
}
