#!/usr/bin/env bash
# Regenerates the audio fixtures for the symphonia specs: 0.5 s of a 440 Hz sine unless stated.
# Made with ffmpeg n9.0.2 (libmp3lame, libvorbis, libopus and ffmpeg's own aac, mp2, flac and alac encoders);
# another ffmpeg may encode slightly differently, so rerun the specs after regenerating.
# Needs ffmpeg and python3. Run from anywhere: bash packages/symphonia/tests/fixtures/generate.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

pinned=(-bitexact -fflags +bitexact -flags:a +bitexact -map_metadata -1 -map_chapters -1)

tone() {
	local sampleRate="$1"
	shift
	ffmpeg -hide_banner -loglevel error -y -f lavfi -i "sine=frequency=440:sample_rate=$sampleRate:duration=0.5" \
		"$@"
}

tone 22050 -ac 2 -c:a pcm_s16le "${pinned[@]}" tone.wav
tone 8000 -ac 1 -c:a pcm_s16le "${pinned[@]}" tone-mono.wav
tone 22050 -ac 1 -c:a adpcm_ima_wav "${pinned[@]}" tone-adpcm.wav
tone 44100 -ac 2 -c:a libmp3lame -b:a 128k -write_xing 1 "${pinned[@]}" tone.mp3
tone 44100 -ac 2 -c:a mp2 -b:a 192k "${pinned[@]}" -f mp2 tone.mp2
tone 32000 -ac 2 -c:a flac "${pinned[@]}" tone.flac
tone 44100 -ac 2 -c:a libvorbis -q:a 2 "${pinned[@]}" tone.ogg
tone 44100 -ac 2 -c:a aac -b:a 96k "${pinned[@]}" -f adts tone.aac
tone 44100 -ac 2 -c:a aac -b:a 96k "${pinned[@]}" tone.m4a
tone 44100 -ac 2 -c:a alac "${pinned[@]}" tone-alac.m4a
tone 11025 -ac 1 -c:a pcm_s16be "${pinned[@]}" tone.aiff
tone 16000 -ac 1 -c:a pcm_s16le "${pinned[@]}" tone.caf
tone 44100 -ac 2 -c:a libvorbis -q:a 2 "${pinned[@]}" -f webm tone-vorbis.webm
tone 48000 -ac 2 -c:a libopus -b:a 64k -frame_duration 20 "${pinned[@]}" tone.opus
tone 48000 -ac 1 -c:a libopus -b:a 48k -frame_duration 60 "${pinned[@]}" tone-60ms.opus
tone 48000 -ac 2 -c:a libopus -b:a 64k -frame_duration 20 "${pinned[@]}" -f webm tone.webm

# 5.1 with 440 Hz on front left, 660 Hz on back right and silence on the other four channels.
ffmpeg -hide_banner -loglevel error -y \
	-f lavfi -i "sine=frequency=440:sample_rate=48000:duration=0.5" \
	-f lavfi -i "sine=frequency=660:sample_rate=48000:duration=0.5" \
	-filter_complex "[0][1]amerge=inputs=2,pan=5.1|FL=c0|FR=0*c0|FC=0*c0|LFE=0*c0|BL=0*c0|BR=c1" \
	-c:a flac "${pinned[@]}" layout-51.flac

# Overs: 0.5 s of a 440 Hz sine in a stereo 32-bit float WAV, peaking at +6 dBFS (amplitude 2.0). Float audio can
# exceed full scale, so decoding it exercises the read-side limiter.
ffmpeg -hide_banner -loglevel error -y -f lavfi -i "aevalsrc=2*sin(2*PI*440*t):s=48000:d=0.5:c=stereo" \
	-c:a pcm_f32le "${pinned[@]}" overs.wav

# Two uncoupled Opus streams. ffmpeg only writes them under mapping family 255 (family 1 couples a stereo pair), so
# the file is encoded with family 255 and its OpusHead's family byte is rewritten to 1, which gives a valid family 1
# head (2 streams, 0 coupled, mapping 0 1) over real two-stream packets. The first Ogg page's CRC is recomputed.
tone 48000 -ac 2 -c:a libopus -b:a 64k -frame_duration 20 -mapping_family 255 "${pinned[@]}" stereo-streams.opus
python3 -I - stereo-streams.opus <<'PYTHON'
import struct
import sys

path = sys.argv[1]
data = bytearray(open(path, "rb").read())
head = data.find(b"OpusHead")

if data[:4] != b"OggS" or head < 0:
	sys.exit(f"{path}: no Ogg page with an OpusHead")

if (data[head + 18], data[head + 19], data[head + 20]) != (255, 2, 0):
	sys.exit(f"{path}: expected mapping family 255 with 2 streams and 0 coupled")

data[head + 18] = 1

segmentCount = data[26]
pageLength = 27 + segmentCount + sum(data[27 : 27 + segmentCount])
crcTable = []

for index in range(256):
	value = index << 24

	for _ in range(8):
		value = ((value << 1) ^ 0x04C11DB7) if value & 0x80000000 else (value << 1)

	crcTable.append(value & 0xFFFFFFFF)

data[22:26] = b"\0\0\0\0"
crc = 0

for byte in data[:pageLength]:
	crc = ((crc << 8) ^ crcTable[((crc >> 24) ^ byte) & 0xFF]) & 0xFFFFFFFF

data[22:26] = struct.pack("<I", crc)
open(path, "wb").write(data)
PYTHON

du -cb ./*.wav ./*.mp3 ./*.mp2 ./*.flac ./*.ogg ./*.aac ./*.m4a ./*.aiff ./*.caf ./*.webm ./*.opus | tail -1
