local construct = require("@util/construct")

local DiscordChannel = require("@classes/channel")
local DiscordUser = require("@classes/user")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.GuildWidget

	The `GuildWidget` class provides a way for developers to interact with a Widget.
]=]

--[=[
	@prop id string
	@within Objects.GuildWidget
]=]

--[=[
	@prop name string
	@within Objects.GuildWidget
]=]

--[=[
	@prop instantInvite string?
	@within Objects.GuildWidget
]=]

--[=[
	@prop channels { Objects.DiscordChannel }
	@within Objects.GuildWidget
]=]

--[=[
	@prop members { Objects.DiscordUser }
	@within Objects.GuildWidget
]=]

--[=[
	@prop presenceCount number
	@within Objects.GuildWidget
]=]

local GuildWidget = {}

GuildWidget.Prototype = {}
GuildWidget.Interface = {}

--[=[
	@prop type string
	@within Objects.GuildWidget
	@readonly

	The type of the GuildWidget. Default is "GuildWidget".
]=]
GuildWidget.Prototype.type = "GuildWidget"

--[=[
	Creates a new GuildWidget instance.

	@function new
	@return GuildWidget
	@within Objects.GuildWidget
]=]
function GuildWidget.Interface.new(
	discordClient: any,
	widgetInformation: {
		id: string,

		[string]: any,
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.GuildWidget, widgetInformation.id, function()
		return construct({
			id = widgetInformation.id,

			discordClient = discordClient,
		}, discordClient.Prototype)
	end)

	if widgetInformation.channels then
		for index, value in widgetInformation.channels do
			widgetInformation.channels[index] = DiscordChannel.from(discordClient, value)
		end
	end

	if widgetInformation.members then
		for index, value in widgetInformation.members do
			widgetInformation.channels[index] = DiscordUser.new(discordClient, value)
		end
	end

	for index, value in widgetInformation do
		self[index] = value
	end

	return self
end

export type GuildWidget = typeof(GuildWidget.Prototype) & {
	discordClient: any,

	id: string,
	name: string,
	instantInvite: string?,
	channels: { DiscordChannel.DiscordChannel },
	members: { DiscordUser.DiscordUser },
	presenceCount: number,
}

return GuildWidget.Interface
