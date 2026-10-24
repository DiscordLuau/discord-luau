---
title: Third-Party Credits
description: Open-source libraries and runtimes used by discord-luau.
sidebar:
  order: 0
---

discord-luau builds on a number of open-source projects. Full licence texts are available in the [`/licences`](https://github.com/DiscordLuau/discord-luau/tree/main/licences) directory of the repository.

## Runtimes

| Project | Author | Licence |
|---|---|---|
| [Lune](https://github.com/lune-org/lune) | Filip Tibell | MPL-2.0 |
| [Zune](https://github.com/Scythe-Technology/Zune) | Scythe Technology | MIT |

## Native Libraries (FFI)

| Library | Author | Licence |
|---|---|---|
| [libsodium](https://libsodium.org) | Frank Denis | ISC |
| [libopus](https://opus-codec.org) 1.6.1, every platform | Xiph.Org Foundation et al. | BSD 3-Clause |
| [libdave](https://github.com/discord/libdave) | Discord | MIT |
| [BoringSSL](https://boringssl.googlesource.com/boringssl) | Google / Eric Young | OpenSSL + ISC |
| [mlspp](https://github.com/cisco/mlspp) | Cisco Systems | BSD 2-Clause |
| [nlohmann/json](https://github.com/nlohmann/json) | Niels Lohmann | MIT |
| [Symphonia](https://github.com/pdeljanov/Symphonia) | Philip Deljanov et al. | MPL-2.0 |

libsymphonia also links [rubato](https://github.com/HEnquist/rubato) (MIT OR Apache-2.0) and the rest of its Rust crate graph, listed with their licences in [`packages/symphonia/native/THIRD_PARTY_NOTICES.md`](https://github.com/DiscordLuau/discord-luau/blob/main/packages/symphonia/native/THIRD_PARTY_NOTICES.md).

## Luau Packages

| Package | Author | Licence |
|---|---|---|
| [luau-futures](https://github.com/YetAnotherClown/luau-futures) | YetAnotherClown | MIT |
| [frktest](https://github.com/itsfrank/frktest) *(test only)* | Francis O'Brien | MIT |
