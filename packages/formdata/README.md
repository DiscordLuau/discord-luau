<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

FormData implementation for Luau, following the multipart/form-data specification.

**Source:** [packages/formdata](https://github.com/DiscordLuau/discord-luau/tree/main/packages/formdata)

## Installation

```bash
pesde add discord_luau/formdata
```

## Example

```luau
local FormData = require("./luau_packages/formdata")

local form = FormData.new()

form:append("username", "Luau")
form:append("avatar", imageBytes, "avatar.png")

local body = form:getBody()

local header = form:getHeader()

local parsed = FormData.parse(responseBody, contentTypeHeader)

if parsed:has("username") then
    print(parsed:get("username"))
end
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
