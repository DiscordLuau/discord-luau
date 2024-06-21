local construct = require("@util/construct")
local extend = require("@util/extend")

local BaseUserChannel = require("base")

local CacheType = require("@enums/cacheType")

--[=[
	@class Objects.UserDMChannel

	Represents the implementation of a Discord Direct Message Channel

	@tag inherit Objects.BaseUserChannel
]=]
local UserDMChannel = {}

UserDMChannel.Prototype = {}
UserDMChannel.Interface = {}

UserDMChannel.Prototype.type = "UserDMChannel"

function UserDMChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
	}
)
	local self = discordClient.discordCache:getDataOr(CacheType.DiscordChannel, channelData.id, function()
		local channelStruct = {
			discordClient = discordClient,
		}

		return construct(channelStruct, UserDMChannel.Prototype)
	end)

	return (extend(self, BaseUserChannel.new(discordClient, channelData)) :: unknown) :: UserDMChannel
end

export type UserDMChannel = BaseUserChannel.BaseUserChannel & typeof(UserDMChannel.Prototype) & {
	discordClient: any,
}

return UserDMChannel.Interface
