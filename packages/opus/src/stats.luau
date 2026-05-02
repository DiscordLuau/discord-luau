--[=[
	@class Opus.Stats

	Analyses a decoded s16le PCM frame and returns human-readable metrics.

	All amplitude values are normalised to 0.0–1.0 relative to the s16 full-scale range (32768).
	dBFS follows the standard convention: 0.0 dBFS is full scale, silence is -math.huge.
]=]

local FULL_SCALE = 32768

export type FrameStats = {
	sampleCount: number,
	durationMs: number,
	peakAmplitude: number,
	rms: number,
	dBFS: number,
	dcOffset: number,
	clippedSamples: number,
}

local Stats = {}

Stats.Interface = {}

--[=[
	@within Opus.Stats

	Analyses `frame` (raw s16le PCM) and returns a `FrameStats` breakdown.

	- `sampleCount` - total s16 samples across all channels
	- `durationMs` - playback duration in milliseconds
	- `peakAmplitude` - loudest sample, normalised 0.0–1.0
	- `rms` - root-mean-square level, normalised 0.0–1.0
	- `dBFS` - RMS level in decibels relative to full scale (≤ 0; -math.huge for silence)
	- `dcOffset` - mean sample value normalised -1.0–1.0 (non-zero suggests a DC bias)
	- `clippedSamples` - samples sitting at ±32767/32768 (full scale saturation)
]=]
function Stats.Interface.stats(frame: buffer, sampleRate: number, channels: number): FrameStats
	local sampleCount = buffer.len(frame) // 2

	local peak = 0
	local sumSquares = 0.0
	local sum = 0.0
	local clippedSamples = 0

	for index = 0, sampleCount - 1 do
		local raw = buffer.readi16(frame, index * 2)
		local absolute = if raw < 0 then -raw else raw

		if absolute > peak then
			peak = absolute
		end

		sumSquares += raw * raw
		sum += raw

		if absolute >= FULL_SCALE - 1 then
			clippedSamples += 1
		end
	end

	local rmsLinear = if sampleCount > 0 then math.sqrt(sumSquares / sampleCount) / FULL_SCALE else 0.0
	local dBFS = if rmsLinear > 0 then 20 * math.log(rmsLinear, 10) else -math.huge
	local samplesPerChannel = if channels > 0 then sampleCount / channels else sampleCount

	return {
		sampleCount = sampleCount,
		durationMs = samplesPerChannel / sampleRate * 1000,
		peakAmplitude = peak / FULL_SCALE,
		rms = rmsLinear,
		dBFS = dBFS,
		dcOffset = if sampleCount > 0 then (sum / sampleCount) / FULL_SCALE else 0.0,
		clippedSamples = clippedSamples,
	}
end

return Stats.Interface
