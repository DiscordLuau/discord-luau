local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local CacheType = require("../../Enums/CacheType")

local BaseUserChannel = require("BaseUserChannel")

--[=[
	@class Objects.UserDMChannel
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
	local channelObject = Construct({
		discordClient = discordClient,
	}, UserDMChannel.Prototype)

	return (Extend(channelObject, BaseUserChannel.new(discordClient, channelData)) :: unknown) :: UserDMChannel
end

export type UserDMChannel = BaseUserChannel.BaseUserChannel & typeof(UserDMChannel.Prototype) & {
	discordClient: any,
}

return UserDMChannel.Interface
