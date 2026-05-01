<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Sodium](https://pesde.dev/packages/discord_luau/sodium)

FFI bindings for [libsodium](https://doc.libsodium.org/), bundling pre-built binaries for all supported platforms - no system installation required.

---

## Security Limitations

This library does its best to handle sensitive material safely, but several limitations are inherent to the runtime and cannot be addressed at the library level.

**What this library does** - all cryptographic operations are delegated to libsodium through FFI. FFI-allocated memory holding keys, passwords, and intermediate state is zeroed with `sodium_memzero` before being freed. All authentication tag comparisons are performed inside libsodium using constant-time functions; no tag is ever compared in Luau code.

**What this library cannot do** - keys returned to the caller live in GC-managed Luau memory. The library has no way to zero GC memory; only the GC can free it, and it never zeroes on collection. Key material may persist in the process heap for an indeterminate period after the variable goes out of scope. This is a known limitation shared by every high-level language that wraps a native crypto library through an FFI layer - Python, Node.js, Lua, and others all have the same constraint. The FFI-side copies are properly zeroed; the Luau-side handles are not.

**Strings cannot be zeroed** - Luau strings are immutable and may be interned in the VM for the lifetime of the process. This is why `pwhash` functions require a `buffer` for passwords rather than a `string`.

**`sodium.sys.lib` is exported** and gives callers direct access to every libsodium FFI binding with no safety wrappers. Incorrect usage will write past allocation bounds and corrupt memory silently. Prefer the high-level modules unless you have a specific reason to use `sys.lib` directly.

---

## Nonce Reuse

`aes256gcm` and `chacha20poly1305` use 12-byte nonces. Reusing any nonce with the same key completely breaks confidentiality and authenticity. Use a strict counter and rotate the key before reaching 2^32 invocations, or use `xchacha20poly1305` which has a 24-byte nonce safe for random generation at scale.

---

## Choosing an Algorithm

| Algorithm | Nonce | Hardware | Nonce strategy |
|-----------|-------|----------|----------------|
| `aes256gcm` | 12 B | AES-NI required | Counter only - check `isAvailable()` first |
| `chacha20poly1305` | 12 B | any CPU | Counter only |
| `xchacha20poly1305` | 24 B | any CPU | Random or counter |

When in doubt, use `xchacha20poly1305`.
