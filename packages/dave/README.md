<p align="center">
  <img src="https://raw.githubusercontent.com/DiscordLuau/docs/master/src/assets/vector.svg" alt="discord-luau" width="96" />
</p>

Implementation of Discord's DAVE end-to-end encryption protocol for voice and video streams.

**Source:** [packages/dave](https://github.com/DiscordLuau/discord-luau/tree/main/packages/dave)

## Installation

```bash
pesde add discord_luau/dave
```

## Example

```luau
local Dave = require("./luau_packages/dave")

local session = Dave.Session.new("auth-session-id", function(source, reason)
    print("MLS failure from", source, ":", reason)
end)

session:init(1, channelGroupId, selfUserId)
session:setExternalSender(externalSenderBytes)

local keyPackage = session:getMarshalledKeyPackage()

voiceServer:sendKeyPackage(keyPackage)

local commit = session:processProposals(proposalsBytes, recognizedUserIds)

if commit then
    voiceServer:sendCommit(commit)
end

local result = session:processCommit(commitBytes)

if not result:isFailed() then
    local ratchet = session:getKeyRatchet(selfUserId)

    local encryptor = Dave.Encryptor.new()

    encryptor:assignSsrcToCodec(ssrc, Dave.sys.codec.opus)
    encryptor:setKeyRatchet(ratchet)

    local encrypted = encryptor:encrypt(Dave.sys.mediaType.audio, ssrc, rawFrame)
end
```

Full documentation at [discordluau-docs.devcomp.workers.dev](https://discordluau-docs.devcomp.workers.dev/).

## Contributing

Contributions are welcome via the repository at [github.com/DiscordLuau/discord-luau](https://github.com/DiscordLuau/discord-luau).

## License

This package is licensed under the MIT License.
