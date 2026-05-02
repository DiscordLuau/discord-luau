<div align="center">
	<p>
		<a href=""><img src="https://raw.githubusercontent.com/DiscordLuau/.github/master/resource/DiscordLuau-Banner.png" width="512" alt="discord-luau"/></a>
	</p>
</div>

## [DiscordLuau - Accumulator](https://pesde.dev/packages/discord_luau/accumulator)

DiscordLuau - Accumulator is a string chunk collector. Since Discord may send data in chunks rather than all at once, the accumulator collects incoming data via `write`, allows inspection via `peek` and `size`, and atomically returns and clears the buffer via `flush`.