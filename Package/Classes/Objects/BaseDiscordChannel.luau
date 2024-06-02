local Construct = require("../../Utils/Construct")

local CacheType = require("../../Enums/CacheType")

local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local Future = require("../../Vendor/Future")

--[=[
	@class Objects.BaseDiscordChannel
]=]
local BaseDiscordChannel = {}

BaseDiscordChannel.Prototype = {}
BaseDiscordChannel.Interface = {}

BaseDiscordChannel.Prototype.type = "BaseDiscordChannel"

--[=[
	Deletes the channel asynchronously.

	@method deleteAsync
	@within Objects.BaseDiscordChannel
	@return Future
]=]
function BaseDiscordChannel.Prototype.deleteAsync(self: BaseDiscordChannel)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotDeleteChannel, self.id))
			:await()
	end)
end

function BaseDiscordChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
	}
)
	return Construct({
		discordClient = discordClient,
	}, BaseDiscordChannel.Prototype)
end

export type BaseDiscordChannel = typeof(BaseDiscordChannel.Prototype) & {
	discordClient: any,

	id: string,
}

return BaseDiscordChannel.Interface
