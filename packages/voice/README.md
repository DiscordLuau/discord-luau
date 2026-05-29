<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Implementation of the Discord voice protocol, including WebSocket signalling, UDP audio transport, RTP encryption, and DAVE E2EE support.

**Source:** [packages/voice](https://github.com/DiscordLuau/discord-luau/tree/main/packages/voice)

## Installation

```bash
pesde add discord_luau/voice
```

## Example

```luau
local voice = require("./luau_packages/voice")

local connection = voice.connection.new({
    shard = shard,
    guildId = "1234567890",
    channelId = "0987654321",
    userId = botUserId,
})

connection:requestVoiceAsync():await()

connection.onReady:listen(function()
    connection:setSpeakingAsync(1):await()

    local frame: buffer = getNextOpusFrame()

    connection:sendOpusAsync(frame):await()
end)

connection.onAudioFrame:listen(function(data)
    print(`audio from {data.userId}, ssrc={data.ssrc}`)
end)

connection:disconnectAsync():await()
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
