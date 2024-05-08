local Intents = require("../Enums/Intents")

local Construct = require("../Utils/Construct")
local FetchKeys = require("../Utils/Dictionary/FetchKeys")

--[=[
	@class DiscordIntents

	https://discord.com/developers/docs/topics/gateway#gateway-intents

	(sorry I will add docs for this lol, just haven't got around to it yet!)

	```lua
		local DiscordLuau = require("../Submodules/DiscordLuau")

		local DiscordIntents = DiscordLuau.DiscordIntents.fromAll()
		local DiscordSettings = DiscordLuau.DiscordSettings.new("BOT TOKEN", DiscordIntents)

		...
	```
]=]
local DiscordIntents = {}

DiscordIntents.Interface = {}
DiscordIntents.Prototype = { }

DiscordIntents.Prototype.type = "DiscordIntents"

DiscordIntents.DispositionMap = {
	[Intents.GuildMembers] = 1,
	[Intents.GuildModeration] = 2,
	[Intents.GuildEmojisAndStickers] = 3,
	[Intents.GuildIntegrations] = 4,
	[Intents.GuildWebhooks] = 5,
	[Intents.GuildInvites] = 6,
	[Intents.GuildVoiceState] = 7,
	[Intents.GuildPresences] = 8,
	[Intents.GuildMessage] = 9,
	[Intents.GuildMessageReactions] = 10,
	[Intents.GuildMessageTyping] = 11,

	[Intents.DirectMessage] = 12,
	[Intents.DirectMessageReactions] = 13,
	[Intents.DirectMessageTyping] = 14,

	[Intents.GuildMessageContent] = 15,
	[Intents.GuildScheduledEvents] = 16,
	[Intents.GuildModerationConfiguration] = 20,
	[Intents.GuildModerationExecution] = 21,
}

--[=[
	@function new
	@within DiscordIntents

	@param intentList { string }

	@return DiscordIntents

	(yet-to-do!)

	```lua

	```
]=]
function DiscordIntents.Interface.new(intentList: { string })
	local intentsValue = 0

	for _, intentEnum in intentList do
		local intentDisposition = DiscordIntents.DispositionMap[intentEnum]

		assert(intentDisposition, `Unexpected intent '{intentEnum}'`)

		intentsValue += bit32.lshift(1, intentDisposition)
	end

	return Construct({
		intents = intentsValue,
	}, DiscordIntents.Prototype)
end

--[=[
	@function fromDefault
	@within DiscordIntents

	@return DiscordIntents

	(yet-to-do!)

	```lua

	```
]=]
function DiscordIntents.Interface.fromDefault()
	local defaultIntents = table.clone(Intents) :: { [string]: any }

	defaultIntents.GuildPresences = nil
	defaultIntents.GuildMembers = nil
	defaultIntents.GuildMessageContent = nil

	return DiscordIntents.Interface.new(FetchKeys(defaultIntents))
end

--[=[
	@function fromAll
	@within DiscordIntents

	@return DiscordIntents

	(yet-to-do!)

	```lua

	```
]=]
function DiscordIntents.Interface.fromAll()
	local allIntents = table.clone(Intents)

	return DiscordIntents.Interface.new(FetchKeys(allIntents))
end

export type DiscordIntents = typeof(DiscordIntents.Prototype) & {}

return DiscordIntents.Interface