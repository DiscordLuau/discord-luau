local Construct = require("../../Utils/Construct")
local Extend = require("../../Utils/Extend")

local CacheType = require("../../Enums/CacheType")

local BaseUserChannel = require("BaseUserChannel")

local Future = require("../../Vendor/Future")

local DiscordEndpoints = require("../../Data/DiscordEndpoints")

local ChannelBuilder = require("../Builders/ChannelBuilder")

--[=[
	@class Objects.UserGroupChannel
]=]
local UserGroupChannel = {}

UserGroupChannel.Prototype = {}
UserGroupChannel.Interface = {}

UserGroupChannel.Prototype.type = "UserGroupChannel"

--[=[
	Modifies the thread channel settings asynchronously.
	
	@method modifyAsync
	@param channelBuilder ChannelBuilder.ChannelBuilder
	@within Objects.UserGroupChannel
	@return Future<unknown>
]=]
function UserGroupChannel.Prototype.modifyAsync(self: UserGroupChannel, channelBuilder: ChannelBuilder.ChannelBuilder)
	return Future.try(function()
		return self.discordClient.discordGateway
			:patchAsync(string.format(DiscordEndpoints.BotModifyChannel, self.id), channelBuilder:toPayloadObject())
			:await()
	end)
end

function UserGroupChannel.Interface.new(
	discordClient,
	channelData: {
		id: string,
	}
)
	local channelObject = Construct({
		discordClient = discordClient,
	}, UserGroupChannel.Prototype)

	return Extend(channelObject, BaseUserChannel.new(discordClient, channelData))
end

export type UserGroupChannel = BaseUserChannel.BaseUserChannel & typeof(UserGroupChannel.Prototype) & {
	discordClient: any,
}

return UserGroupChannel.Interface
