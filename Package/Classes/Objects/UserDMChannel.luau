local Construct = require("@Utils/Construct")
local Extend = require("@Utils/Extend")

local BaseUserChannel = require("@Objects/BaseUserChannel")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.UserDMChannel

	Represents the implementation of a Discord Direct Message Channel

	=@inherit Objects.BaseUserChannel
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

		return Construct(channelStruct, UserDMChannel.Prototype)
	end)

	return (Extend(self, BaseUserChannel.new(discordClient, channelData)) :: unknown) :: UserDMChannel
end

export type UserDMChannel = BaseUserChannel.BaseUserChannel & typeof(UserDMChannel.Prototype) & {
	discordClient: any,
}

return UserDMChannel.Interface
