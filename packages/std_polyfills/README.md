<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Polyfills for stdlib functions across multiple Luau runtimes (Lune, Zune, Eryx, Roblox).

**Source:** [packages/std_polyfills](https://github.com/DiscordLuau/discord-luau/tree/main/packages/std_polyfills)

## Installation

```bash
pesde add discord_luau/std_polyfills
```

## Example

```luau
local polyfills = require("./luau_packages/std_polyfills")

local runtime = polyfills.runtime.getRuntime()

print("Running on:", runtime)

local caps = polyfills.runtime.capabilities()

if caps.ffi then
    -- load FFI-dependent libraries
end

local now = polyfills.datetime.now()

local response = polyfills.net.request({
    url = "https://discord.com/api/v10/gateway",
    method = "GET",
})

print(response.statusCode, response.body)
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
