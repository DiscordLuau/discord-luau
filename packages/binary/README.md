<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Discord-Luau Binary provides platform-aware binary acquisition for FFI packages. It probes system library paths before falling back to a local cache, downloading and verifying binaries from GitHub release assets on first use.

**Source:** [packages/binary](https://github.com/DiscordLuau/discord-luau/tree/main/packages/binary)

## Installation

```bash
pesde add discord_luau/binary
```

## Example

```luau
local binary = require("./luau_packages/binary")

local libsodium = binary.load({
    id = "libsodium",
    version = "0.0.1",
    url = "https://github.com/DiscordLuau/discord-luau/releases/download/sodium-{version}/libsodium-{os}-{arch}{ext}",
    checksum = "sha256:abc123...",
})

-- libsodium.path is the absolute path to the cached binary on disk
local lib = stdPolyfills.ffi.dlopen(libsodium.path, { ... })
```

The URL template supports `{version}`, `{os}`, `{arch}`, and `{ext}` tokens. `{os}` resolves to `linux`, `macos`, or `windows`; `{arch}` to `x64` or `arm64`; `{ext}` to `.so`, `.dylib`, or `.dll`.

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
