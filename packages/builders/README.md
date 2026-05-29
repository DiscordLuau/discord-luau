<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Builders used to generate payloads that the Discord API can parse. If you are unfamiliar with what the Discord API expects, builders provide a simple and discoverable interface for constructing embeds, messages, components, interactions, and more without needing to know the raw payload structure.

**Source:** [packages/builders](https://github.com/DiscordLuau/discord-luau/tree/main/packages/builders)

## Installation

```bash
pesde add discord_luau/builders
```

## Example

```luau
local Builders = require("./luau_packages/builders")

local embed = Builders.embed.embed.new()
    :setTitle("Hello, world!")
    :setDescription("Built with discord-luau.")
    :setColor(0x5865F2)
    :build()

local button = Builders.message.components.button.new()
    :setStyle("Primary")
    :setLabel("Click me")
    :setCustomId("my_button")
    :build()

local actionRow = Builders.message.components.actionRow.new()
    :addComponent(button)
    :build()
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
