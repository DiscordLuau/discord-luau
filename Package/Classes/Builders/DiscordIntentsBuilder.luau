local Intents = require("../../Enums/Intents")

local Construct = require("../../Utils/Construct")
local FetchKeys = require("../../Utils/Dictionary/FetchKeys")

--[=[
	@class Builders.DiscordIntentsBuilder

	DiscordIntentsBuilder is used to construct intents for a Discord bot, specifying which events the bot will receive.

	Usage:
	```lua
	local DiscordLuau = require("../Submodules/DiscordLuau")

	local DiscordIntentsBuilder = DiscordLuau.DiscordIntentsBuilder.fromAll()
	local DiscordSettings = DiscordLuau.DiscordSettings.new("BOT TOKEN", DiscordIntentsBuilder)
	```
]=]
local DiscordIntentsBuilder = {}

DiscordIntentsBuilder.Interface = {}
DiscordIntentsBuilder.Prototype = {}

DiscordIntentsBuilder.Prototype.type = "DiscordIntentsBuilder"

DiscordIntentsBuilder.DispositionMap = {
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
	
	Creates a new instance of DiscordIntentsBuilder with the specified intents.
	
	@function new
	@param intentList { string } -- A list of intents to include.
	@within Builders.DiscordIntentsBuilder
	@return Builders.DiscordIntentsBuilder -- A new instance of DiscordIntentsBuilder.
]=]
function DiscordIntentsBuilder.Interface.new(intentList: { string })
	local intentsValue = 0

	for _, intentEnum in intentList do
		local intentDisposition = DiscordIntentsBuilder.DispositionMap[intentEnum]

		assert(intentDisposition, `Unexpected intent '{intentEnum}'`)

		intentsValue += bit32.lshift(1, intentDisposition)
	end

	return Construct({
		intents = intentsValue,
	}, DiscordIntentsBuilder.Prototype)
end

--[=[
	Creates a new instance of DiscordIntentsBuilder with the default intents.
	
	@function fromDefault
	@within Builders.DiscordIntentsBuilder
	@return Builders.DiscordIntentsBuilder -- A new instance of DiscordIntentsBuilder.
]=]
function DiscordIntentsBuilder.Interface.fromDefault()
	local defaultIntents = table.clone(Intents) :: { [string]: any }

	defaultIntents.GuildPresences = nil
	defaultIntents.GuildMembers = nil
	defaultIntents.GuildMessageContent = nil

	return DiscordIntentsBuilder.Interface.new(FetchKeys(defaultIntents))
end

--[=[
	Creates a new instance of DiscordIntentsBuilder with all available intents.
	
	@function fromAll
	@within Builders.DiscordIntentsBuilder
	@return Builders.DiscordIntentsBuilder -- A new instance of DiscordIntentsBuilder.
]=]
function DiscordIntentsBuilder.Interface.fromAll()
	local allIntents = table.clone(Intents)

	return DiscordIntentsBuilder.Interface.new(FetchKeys(allIntents))
end

export type DiscordIntentsBuilder = typeof(DiscordIntentsBuilder.Prototype) & {}

return DiscordIntentsBuilder.Interface
