local construct = require("@util/construct")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.DiscordEmoji

	The `DiscordEmoji` class represents a Discord emoji and provides a structure for emoji data.
]=]

--[=[
	@prop id string
	@within Objects.DiscordEmoji
]=]

--[=[
	@prop name string
	@within Objects.DiscordEmoji
]=]

--[=[
	@prop roles { string }
	@within Objects.DiscordEmoji
]=]

--[=[
	@prop requireColons boolean
	@within Objects.DiscordEmoji
]=]

--[=[
	@prop managed boolean
	@within Objects.DiscordEmoji
]=]

--[=[
	@prop animated boolean
	@within Objects.DiscordEmoji
]=]

--[=[
	@prop available boolean
	@within Objects.DiscordEmoji
]=]

local DiscordEmoji = {}

DiscordEmoji.Prototype = {}
DiscordEmoji.Interface = {}

--[=[
	@prop type string
	@within Objects.DiscordEmoji
	@readonly

	The type of the DiscordEmoji. Default is "DiscordEmoji".
]=]
DiscordEmoji.Prototype.type = "DiscordEmoji"

--[=[
	Creates a new DiscordEmoji instance.

	@function new
	@param discordClient any -- The Discord client instance.
	@param emojiData table -- The raw data for the emoji.
	@return DiscordEmoji -- The newly created DiscordEmoji instance.
	@within Objects.DiscordEmoji
]=]
function DiscordEmoji.Interface.new(
	discordClient: any,
	emojiData: {
		id: string,
		name: string,
		roles: { string },
		requireColons: boolean,
		managed: boolean,
		animated: boolean,
		available: boolean,
	}
)
	return discordClient.discordCache:getDataOr(CacheType.DiscordEmoji, emojiData.id, function()
		local emojiStruct = {
			discordClient = discordClient,
		}

		for index, value in emojiData do
			emojiStruct[index] = value
		end

		return construct(emojiStruct, DiscordEmoji.Prototype)
	end)
end

export type DiscordEmoji = typeof(DiscordEmoji.Prototype) & {
	id: string,
	name: string,
	roles: { string },
	requireColons: boolean,
	managed: boolean,
	animated: boolean,
	available: boolean,
}

return DiscordEmoji.Interface
