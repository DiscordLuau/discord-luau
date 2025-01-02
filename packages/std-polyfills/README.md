<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## DiscordLuau - Std Polyfills

DiscordLuau - Std Polyfills provides polyfills for the standard library. When transitioning Discord-Luau to a new Luau runtime, ensure the standard library is fully polyfilled.

All Discord-Luau packages depend on this package as a core dependency.

### Installation

To use DiscordLuau State, add it to your project using the pesde package manager:

```bash
pesde add discord_luau/std_polyfills
```

### Getting Started

1. Require the library in your project:
```luau
local Std = require("./lune_packages/std_polyfills")
```

2. Use the provided library:
```luau
local DateTime = Std.datetime.now()
```

### Contributing
We welcome contributions! If you find an issue or have ideas for improvement:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request.

Please ensure your contributions align with our contribution guidelines.

### License
This project is licensed under the MIT License. Feel free to use it in your projects.