<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

FFI bindings for libsodium, providing AES-256-GCM authenticated encryption, hashing, signing, and key derivation with pre-built binaries for all supported platforms.

**Source:** [packages/sodium](https://github.com/DiscordLuau/discord-luau/tree/main/packages/sodium)

## Installation

```bash
pesde add discord_luau/sodium
```

## Example

```luau
local sodium = require("./luau_packages/sodium")

-- AES-256-GCM (requires AES-NI hardware support)
if sodium.aes256gcm.isAvailable() then
    local key = sodium.aes256gcm.keygen()

    local nonce = sodium.randombytes.buf(sodium.aes256gcm.NONCE_BYTES)

    local data = buffer.fromstring("hello, world")

    local encrypted = sodium.aes256gcm.encrypt(data, key, nonce)

    local decrypted = sodium.aes256gcm.decrypt(
        encrypted.cipher, encrypted.tag, key, nonce
    )

    print(buffer.tostring(decrypted))
end

local key = sodium.secretbox.keygen()

local nonce = sodium.secretbox.nonce()

local message = buffer.fromstring("secret message")

local sealed = sodium.secretbox.seal(message, key, nonce)

local plaintext = sodium.secretbox.open(sealed, key, nonce)

print(buffer.tostring(plaintext))
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
