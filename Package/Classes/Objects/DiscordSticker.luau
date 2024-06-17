local Construct = require("@Utils/Construct")

local DiscordUser = require("@Objects/DiscordUser")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.DiscordSticker

	The `DiscordSticker` class represents a Discord sticker and provides a structure for sticker data.
]=]
local DiscordSticker = {}

DiscordSticker.Prototype = {}
DiscordSticker.Interface = {}

--[=[
	@prop type string
	@within Objects.DiscordSticker
	@readonly

	The type of the DiscordSticker. Default is "DiscordSticker".
]=]
DiscordSticker.Prototype.type = "DiscordSticker"

--[=[
	Creates a new DiscordSticker instance.

	@function new
	@param discordClient any -- The Discord client instance.
	@param emojiData table -- The raw data for the emoji.
	@return DiscordSticker -- The newly created DiscordSticker instance.
	@within Objects.DiscordSticker
]=]
function DiscordSticker.Interface.new(
	discordClient: any,
	stickerData: {
		id: string,

		[string]: any,
	}
)
	--[=[
		@prop id string
		@within Objects.DiscordSticker
	]=]

	--[=[
		@prop packId string
		@within Objects.DiscordSticker
	]=]

	--[=[
		@prop name string
		@within Objects.DiscordSticker
	]=]

	--[=[
		@prop description string
		@within Objects.DiscordSticker
	]=]

	--[=[
		@prop tags string
		@within Objects.DiscordSticker
	]=]

	--[=[
		@prop type number
		@within Objects.DiscordSticker
	]=]

	--[=[
		@prop formatType number
		@within Objects.DiscordSticker
	]=]

	--[=[
		@prop avaliable boolean?
		@within Objects.DiscordSticker
	]=]

	--[=[
		@prop guildId string?
		@within Objects.DiscordSticker
	]=]

	--[=[
		@prop user Objects.DiscordUser?
		@within Objects.DiscordSticker
	]=]

	--[=[
		@prop sortValue number?
		@within Objects.DiscordSticker
	]=]
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordSticker, stickerData.id, function()
		local emojiStruct = {
			discordClient = discordClient,
		}

		return Construct(emojiStruct, DiscordSticker.Prototype)
	end)

	if stickerData.user then
		stickerData.user = DiscordUser.new(discordClient, stickerData.user)
	end

	for index, value in stickerData do
		self[index] = value
	end

	return self
end

export type DiscordSticker = typeof(DiscordSticker.Prototype) & {
	id: string,
	packId: string,
	name: string,
	description: string,
	tags: string,
	type: number,
	formatType: number,
	avaliable: boolean?,
	guildId: string?,
	user: DiscordUser.DiscordUser?,
	sortValue: number?,
}

return DiscordSticker.Interface
