<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Decodes audio files and streams to 48 kHz stereo PCM, through a small Rust wrapper around [Symphonia](https://github.com/pdeljanov/Symphonia).

**Source:** [packages/symphonia](https://github.com/DiscordLuau/discord-luau/tree/main/packages/symphonia)

## Installation

```bash
pesde add discord_luau/symphonia
```

## Example

```luau
local symphonia = require("./luau_packages/symphonia")

local decoder = symphonia.decoder.fromFile("song.flac")

while true do
	local pcm = decoder:read()

	if not pcm then
		break
	end
end

decoder:destroy()
```

Runs on Zune. Each `read` returns about 100 ms of 16-bit stereo PCM.

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
