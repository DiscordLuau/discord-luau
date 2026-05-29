<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Library enabling developers to query information from Discord snowflake IDs.

**Source:** [packages/snowflake](https://github.com/DiscordLuau/discord-luau/tree/main/packages/snowflake)

## Installation

```bash
pesde add discord_luau/snowflake
```

## Example

```luau
local Snowflake = require("./luau_packages/snowflake")

local snowflake = Snowflake.new("175928847299117063")

local timestamp = snowflake:getTimestamp()

print(timestamp.unixTimestamp)
print(timestamp:toIsoDate())

local workerId = snowflake:getInternalWorkerId()

local processId = snowflake:getInternalProcessId()

local increment = snowflake:getIncrement()
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
