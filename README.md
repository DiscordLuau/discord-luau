<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD041 -->

<div align="center">
 <p>
  <a href="">
   <img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/>
 </a>
 </p>
</div>

## About

This is the **[Discord API](https://discord.com/developers/docs/intro) [Wrapper](https://rapidapi.com/blog/api-glossary/api-wrapper/)**, the resource that you'll be interacting with if you want to create a Discord Bot/Application! 🎉

### Project Structure

- `init.luau`: Primary entrypoint to the main discord-luau library
- `packages/discord-luau`: The source code for the discord-luau package
- - `src/classes`: All discord-luau generated obejcts/classes that the user can interact with.
- - `src/data`: Internal library 'data' modules, consisting of generic lua datatypes, with string values.
- - `src/enums`: Internal library 'enum' files, consisting of string keys and values.
- `packages/lune-std-polyfills`: A set of polyfills for the lune standard library, so that discord-luau can run on runtimes other than lune in the future.
- `packages/utils`: Utility functions discord-luau depends on
- `packages/vendor`: A collecction of external dependencies, customized for discord-luau

### Project Status

At the moment, I *([AsynchronousMatrix](https://github.com/4x8Matrix))* will write to the Master branch every now and again, if I introduce breaking changes, I may put that into it's own branch, but at the moment, since there's no `0.1.0` version in sight, the Master branch is where I lurk, adding potentially breaking changes every now and again..!

Pull Requests are welcome!

### Project Goals

- Enabling developers to create a discord bot that connect to the Discord Websocket.
- Send and recieve messages from a Discord websoket.
- Take full advantage of the Discord REST Http Library.
- Provide detailed and clear documentation on the Discord API Wrapper

## [Read the Documentation](https://discord-luau-docs.deno.dev)
