<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Example project demonstrating how to build a Discord bot with discord-luau. It joins a voice channel and plays a song through `discord_luau/audio`.

**Source:** [packages/example](https://github.com/DiscordLuau/discord-luau/tree/main/packages/example)

## Getting Started

Clone the repository and install dependencies:

```bash
git clone https://github.com/DiscordLuau/discord-luau
cd discord-luau
pesde install
```

Create a `.env.luau` file at the root of the repository returning a table with your bot token (without the `Bot ` prefix, which the library adds):

```luau
return {
    DISCORD_BOT_TOKEN = "YOUR_TOKEN_HERE",
}
```

Put the song to play at `packages/example/song.mp3`; git ignores it. Any format `audio.fromFile` reads works, such as FLAC, Ogg or WAV, if you change `SONG_PATH` in `src/init.luau` to match.

The bot needs the Connect and Speak permissions in the voice channel the example joins (`VOICE_CHANNEL_ID` in `src/init.luau`). Join that channel yourself before you start the bot: in a channel with DAVE end-to-end encryption, a bot alone never receives the group's key, so what it plays goes out as silence.

Run the example (Zune only; voice and audio load native libraries through FFI):

```bash
zune packages/example/src
```

## Documentation

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This project is licensed under the MIT License.
