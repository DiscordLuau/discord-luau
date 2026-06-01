# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- All bitflag classes (`ApplicationBitflag`, `AttachmentBitflag`, `ChannelBitflag`, `GuildMemberBitflag`, `MessageBitflag`, `RoleBitflag`, `SystemChannelBitflag`) now store `flag` internally as a `string` - constructors still accept `number` from JSON and convert via `tostring`
- `Permission` class now stores the permission bitfield as a `string` rather than `number`, matching Discord's own representation
- Shard calculation in `VoiceBehaviour.joinAsync` now passes the guild snowflake string directly to the bit library instead of calling `tonumber` first

## 0.0.2

### Fixed

- `formatType` resolving to an invalid type in `ApiTypes`, should be `StickerFormatTypes` and not `StickerFormatType`
- `FutureLike` return casts in `User.getDmChannelIdAsync` and `VoiceBehaviour` methods now go through `any` to satisfy strict type analysis

## 0.0.1

- Initial release on Pesde. Package versioning is now managed through CI.
