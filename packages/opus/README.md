<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

FFI bindings for libopus, providing Opus audio encoding and decoding with pre-built binaries for all supported platforms.

**Source:** [packages/opus](https://github.com/DiscordLuau/discord-luau/tree/main/packages/opus)

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

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
