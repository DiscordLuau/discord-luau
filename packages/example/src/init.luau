local discordLuau = require("@self/../luau_packages/discord")
local discordBuilders = require("@self/../luau_packages/builders")
local audio = require("@self/../luau_packages/audio")

local env = require("@self/../../../.env")

local VOICE_CHANNEL_ID = "1266808027668021268"
local SONG_PATH = "packages/example/song.mp3"

local bot = discordLuau.bot.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = discordBuilders.intents.new({ "Guilds", "GuildVoiceStates" }):build(),
})

bot.onAllShardsReady:listenOnce(function()
	local fetched = bot:getVoiceChannelAsync(VOICE_CHANNEL_ID):await()

	if fetched:isErr() then
		bot.logger:warn(`could not find the voice channel: {fetched:unwrapErr()}`)

		return
	end

	local channel = fetched:unwrapOk()
	local joined = channel:joinAsync():await()

	if joined:isErr() then
		bot.logger:warn(`could not join the voice channel: {joined:unwrapErr()}`)

		return
	end

	local player = audio.player.new(joined:unwrapOk())

	bot.logger:info(`playing {SONG_PATH}`)

	local played = player:playAsync(audio.fromFile(SONG_PATH)):await()

	if played:isErr() then
		bot.logger:warn(`could not play the song: {played:unwrapErr()}`)

		return
	end

	bot.logger:info(`the song {played:unwrapOk()}`)
end)

local connected = bot:connectAsync():await()

if connected:isErr() then
	bot.logger:warn(`could not connect: {connected:unwrapErr()}`)
end
