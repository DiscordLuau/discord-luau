<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## About

This is the **[Discord API](https://discord.com/developers/docs/intro) [Wrapper](https://rapidapi.com/blog/api-glossary/api-wrapper/)**, the resource that you'll be interacting with if you want to create a Discord Bot/Application! 🎉

### Project Structure

- `init.luau`: Requires Package/init.luau
- `/Package`: The source code for the Discord-Luau package
- - `/Package/Classes`: All Discord-Luau generated obejcts/classes that the user can interact with.
- - `/Package/Data`: Internal library 'data' modules, consisting of generic lua datatypes, with string values.
- - `/Package/Enums`: Internal library 'enum' files, consisting of string keys and values.
- - `/Package/Std`: Standard libraries that this library uses, if Discord-Luau were to switch to another Runtime, we'd just need to modify the `/Package/Std` folder to support the standard libraries for another Runtime.
- - `/Package/Types`: Some awkward types that we need support for in Discord Luau
- - `/Package/Utils`: Utility functions Discord Luau uses
- - `/Package/Vendor`: Vendor, external resources or packages that Discord Luau uses
- - `/Package/init.luau`: Entrypoint for Discord Luau

### Project Status

At the moment, I *([AsynchronousMatrix](https://github.com/4x8Matrix))* will write to the Master branch every now and again, if I introduce breaking changes, I may put that into it's own branch, but at the moment, since there's no `0.1.0` version in sight, the Master branch is where I lurk, adding potentially breaking changes every now and again..!

Pull Requests are welcome! But there's no guarntee that what has been written in that Pull Request will be merged..! 

### Project Goals

- Enabling developers to create a discord bot that connect to the Discord Websocket.
- Send and recieve messages from a Discord websoket.
- Take full advantage of the Discord REST Http Library.
- Provide detailed and clear documentation on the Discord API Wrapper

## Documentation

Please head on over to the [Wiki](https://github.com/DiscordLuau/Discord-Luau/wiki) for further details, however, i'll soon enough set up a dedicated website for Discord Luau!

## Examples

Please take a look at the [/Examples](https://github.com/DiscordLuau/Discord-Luau/tree/Master/Examples) folder under the Master branch!
