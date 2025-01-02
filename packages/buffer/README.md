<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## DiscordLuau - Buffer

DiscordLuau - Buffer, not to be confused with the luau buffer datatype, is a library that helps us temporary buffer binary data, this is required as discord may send up parts of a chunk - and not the entire chunk, so we need to buffer the data until we have the entire chunk.

### Installation

To use DiscordLuaus Bit, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/buffer
```

### Getting Started

1. Require the library in your project:
```luau
local Buffer = require("./luau_packages/buffer")
```

2. Use the provided library to store/flush binary data:
```luau
local zlibBuffer = buffer.new(),

zlibBuffer:write(xyz)

...

local completeMessage = zlibBuffer:flush()
```

### Contributing
We welcome contributions! If you find an issue or have ideas for improvement:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request.

Please ensure your contributions align with our contribution guidelines.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.