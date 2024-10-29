local botObject = require("@core/bot")

local intentsBuilder = require("@builders/intents")

local env = require(".env")

local discordIntents = intentsBuilder.new()

discordIntents:addIntent("Guilds")

local discordBot = botObject.new({
	token = env.DISCORD_BOT_TOKEN,
	intents = discordIntents:build(),
})

discordBot.onAllShardsReady:listen(function()
	assert(discordBot.application, ``)

	-- local guild = discordBot:getGuildAsync("1273035219561091193"):expect("1")

	-- for _, member in guild:listGuildMembersAsync(nil, 10):expect("2") do
	-- 	print(member.user)
	-- end

	-- local member = guild:getGuildMemberAsync("685566749516628033"):expect("2")

	-- print(member)

	-- local threads = guild:getThreadsAsync():catch(function(error, traceback)
	-- 	warn(error)
	-- 	print(traceback)
	-- end)

	-- print(threads:expect(`Uh oh, but on the second one?!`))

	-- guild
	-- 	:modifyGuildAsync(guildBuilder
	-- 		.new({
	-- 			name = "Discord Luau",
	-- 		})
	-- 		:build())
	-- 	:after(function()
	-- 		print("RENAMED!")
	-- 	end)

	-- local preview = guild:fetchGuildPreviewAsync():expect(`2`)

	-- local guildTextChannels = guild:getTextChannelsAsync():expect(`Uh oh, but on the second one?!`)

	-- for _, channel in guildTextChannels do
	-- 	print(channel.name)
	-- end
end)

discordBot:connectAsync():after(function()
	print("Connected to Discord!")
end)
