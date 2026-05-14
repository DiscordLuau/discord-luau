local discordLuau = require("@self/../luau_packages/discord")
local discordBuilders = require("@self/../luau_packages/builders")
local opus = require("@self/../luau_packages/opus")

local env = require("@self/../../../.env")

local MAX_BARS = 60
local MIN_DBFS = -40

local discordBot = discordLuau.bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = discordBuilders.intents.new({ "Guilds", "GuildMessages" }):build(),
	reconnect = true,
})

discordBot.onAllShardsReady:listenOnce(function()
	local channel = discordBot:getVoiceChannelAsync("1266808027668021268"):await():unwrapOk()

	channel.onAudioFrame:listen(function(object)
		local frameStats = opus.stats(object.frame, opus.DISCORD_SAMPLE_RATE, opus.DISCORD_CHANNELS)

		local bars = 0

		if frameStats.dBFS ~= -math.huge then
			bars = math.floor(math.clamp((frameStats.dBFS - MIN_DBFS) / -MIN_DBFS, 0, 1) * MAX_BARS)
		end

		local userId = object.userId or "unknown"
		print(
			`{userId}: {("█"):rep(bars)}{("░"):rep(MAX_BARS - bars)} {string.format("%.1f", frameStats.dBFS)} dBFS`
		)
	end)

	channel:joinAsync():await()
end)

discordBot:connectAsync():poll()
