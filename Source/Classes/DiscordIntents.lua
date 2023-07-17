local DiscordIntents = {}

DiscordIntents.Type = "DiscordIntents"

DiscordIntents.Internal = {}
DiscordIntents.Interface = {}
DiscordIntents.Prototype = {
	Internal = DiscordIntents.Internal,
}

DiscordIntents.Interface.Intents = {
	["GuildMembers"] = 1,
	["GuildModeration"] = 2,
	["GuildEmojisAndStickers"] = 3,
	["GuildIntegrations"] = 4,
	["GuildWebhooks"] = 5,
	["GuildInvites"] = 6,
	["GuildVoiceState"] = 7,
	["GuildPresences"] = 8,
	["GuildMessage"] = 9,
	["GuildMessageReactions"] = 10,
	["GuildMessageTyping"] = 11,

	["DirectMessage"] = 12,
	["DirectMessageReactions"] = 13,
	["DirectMessageTyping"] = 14,

	["GuildMessageContent"] = 15,
	["GuildScheduledEvents"] = 16,
	["GuildModerationConfiguration"] = 20,
	["GuildModerationExecution"] = 21,
}

function DiscordIntents.Prototype:Add(intent)
	if table.find(self.Intents, intent) then
		return
	end

	table.insert(self.Intents, intent)
end

function DiscordIntents.Prototype:Remove(intent)
	local index = table.find(self.Intents, intent)

	if not index then
		return
	end

	table.remove(self.Intents, index)
end

function DiscordIntents.Prototype:ToJSONObject()
	local intents = 0

	for _, intentValue in self.Intents do
		intents += bit32.lshift(1, intentValue)
	end

	return intents
end

function DiscordIntents.Prototype:ToString()
	return `{DiscordIntents.Type}<{table.concat(self.Intents, ", ")}>`
end

function DiscordIntents.Interface.new(intents)
	return setmetatable({
		Intents = intents or {},
	}, {
		__index = DiscordIntents.Prototype,
		__type = DiscordIntents.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

function DiscordIntents.Interface.default()
	local defaultIntents = table.clone(DiscordIntents.Interface.Intents)

	defaultIntents.GuildPresences = nil
	defaultIntents.GuildMembers = nil
	defaultIntents.GuildMessageContent = nil

	return DiscordIntents.Interface.new(defaultIntents)
end

return DiscordIntents.Interface
