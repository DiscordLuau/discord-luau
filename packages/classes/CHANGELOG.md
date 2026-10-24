# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 0.0.7

### Added

- Voice channel objects forward `onMediaReady`, which fires when audio can flow on the guild's voice connection (with DAVE, after `onReady`); the `onDaveEpochTransition` docs say what its number counts

### Changed

- Helper methods drop their leading underscore (`_name` is now `name`); they stay marked `@private` and out of the docs
- The voice channel docs describe `onRawAudioFrame`, `onAudioFrame`, `onReady` and `onMediaReady` as the connection does, and point at `discord_luau/audio` for playback
- `VoiceChannel:joinAsync()` resolves with the guild's voice `Connection` once it is ready and fails with a reason; a guild has one connection, so joining another channel of the guild leaves the old one first, and joining the same channel again resolves with the existing connection
- Voice identifies as the bot's user ID instead of the application ID, which differs on older applications
- The `connection` docs say how to switch off Opus decoding with `connection.decodeAudio`

### Fixed

- `VoiceChannel:leaveAsync()` sends the gateway leave and works from any channel object of the guild; it used to be a no-op unless called on the exact object that joined
- Voice connections are keyed by guild in `state.voiceConnections`, not by channel
- A voice join fails at once, with a message saying so, before READY or without the `GuildVoiceStates` intent, instead of waiting for events Discord will never send
- `VoiceChannel:sendOpusAsync()` and `setSpeakingAsync()` return an Err when the guild has no voice connection, instead of throwing before a future exists

## 0.0.6

### Added

- `Message` now exposes a `guildId` field populated from `guild_id` in the message payload; nil for DM messages

## 0.0.5

### Fixed

- `Role.modifyAsync` now accepts `apiTypes.ModifyGuildRoleRequest` instead of `builders.roleJSON`, allowing partial role update tables without requiring all fields to be present
- `VoiceBehaviour.joinAsync` shard ID calculation now has an explicit `number` type cast on the `tonumber` result to satisfy strict type analysis

## 0.0.4

### Changed

- Internal dependency version constraints updated to open-ended ranges so pesde resolves to the latest published version automatically

## 0.0.3

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
