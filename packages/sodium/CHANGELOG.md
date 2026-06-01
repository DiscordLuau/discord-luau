# 0.0.2

## Changes

- Binaries are no longer bundled with the package. The `binary` package is now used to resolve, cache, and download the platform-specific `libsodium` shared library on first use. This was necessary because pesde does not permit binary uploads.
