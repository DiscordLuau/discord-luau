<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

FFI bindings for libopus, providing Opus audio encoding and decoding with pre-built binaries for all supported platforms.

**Source:** [packages/opus](https://github.com/DiscordLuau/discord-luau/tree/main/packages/opus)

Opus needs FFI, so it runs on Zune; on a runtime without FFI, creating an encoder or decoder raises `Opus requires FFI which is not available on this runtime (accessed: <name>)`. The `DISCORD_*` constants and `Opus.stats` are plain Luau and work anywhere.

## Installation

```bash
pesde add discord_luau/opus
```

## Example

```luau
local Opus = require("./luau_packages/opus")

local encoder = Opus.encoder.new(
    Opus.DISCORD_SAMPLE_RATE,
    Opus.DISCORD_CHANNELS,
    Opus.application.voip
)

local decoder = Opus.decoder.new(
    Opus.DISCORD_SAMPLE_RATE,
    Opus.DISCORD_CHANNELS
)

local packet: buffer = encoder:encode(pcmFrame)

local decoded: buffer = decoder:decode(packet)

encoder:destroy()

decoder:destroy()
```

`encoder:encode(pcmFrame)` takes exactly one Opus frame of interleaved 16-bit little-endian PCM: 2.5, 5, 10, 20, 40 or 60 ms of samples for every channel. For Discord's 20 ms of stereo at 48 kHz that is 960 samples per channel, 3840 bytes. `audio.fromPCM` in [`discord_luau/audio`](https://github.com/DiscordLuau/discord-luau/tree/main/packages/audio) cuts PCM of any length into such frames for you.

When a packet is lost, `decoder:decodeFec(nextPacket)` recovers it from the forward error correction data in the packet after it, and `decoder:decodePLC()` conceals it when there is no such packet. `Opus.stats(pcm, Opus.DISCORD_SAMPLE_RATE, Opus.DISCORD_CHANNELS)` measures a decoded frame: its peak, RMS, dBFS, DC offset and clipped samples.

## Encoder settings

`encoder:setBitrate(bitsPerSecond)` sets the target bitrate, a whole number from 500 to 510000, and `encoder:getBitrate()` reads back what libopus uses. `Opus.checkBitrate(bitsPerSecond)` raises `bitrate must be a whole number from 500 to 510000 bits per second` for anything else, so you can check a value before an encoder exists. `encoder:setSignal("voice" | "music" | "auto")` tells libopus what the audio is, and `encoder:getSignal()` reads it. All four raise `Encoder has been destroyed` after `destroy`.

```luau
encoder:setBitrate(128000)
encoder:setSignal("music")
```

## Platforms

The package ships libopus 1.6.1, built from source and reproducible, for linux-x64, linux-arm64, macos-x64, macos-arm64, windows-x64 and windows-x86. It always loads its own checksummed copy and never a libopus installed on the system. On Windows the library needs the Universal C Runtime (UCRT), which is built into Windows 10 and later; older Windows needs Microsoft's UCRT update.

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
