<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Example project demonstrating how to build a Discord bot with discord-luau.

**Source:** [packages/example](https://github.com/DiscordLuau/discord-luau/tree/main/packages/example)

## Getting Started

Clone the repository and install dependencies:

```bash
git clone https://github.com/DiscordLuau/discord-luau
cd discord-luau
pesde install
```

Create a `.env.luau` file at the root of the repository returning a table with your bot token:

```luau
return {
    DISCORD_TOKEN = "Bot YOUR_TOKEN_HERE",
}
```

Run the example:

```bash
zune packages/example/src
```

## Documentation

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This project is licensed under the MIT License.
