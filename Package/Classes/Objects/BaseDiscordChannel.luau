local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

--[=[
	@class Objects.BaseDiscordChannel

	Represents a base discord channel, every discord channel object will extend from this as a base.
]=]
local BaseDiscordChannel = {}

BaseDiscordChannel.Prototype = {}
BaseDiscordChannel.Interface = {}

BaseDiscordChannel.Prototype.type = "BaseDiscordChannel"

--[=[
	Deletes the channel asynchronously.

	@method deleteAsync
	@within Objects.BaseDiscordChannel
	@return Vendor.Future
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

		[any]: any,
	}
): BaseDiscordChannel
	--[=[
		@prop id string
		@within Objects.BaseDiscordChannel
	]=]

	--[=[
		@prop type number
		@within Objects.BaseDiscordChannel
	]=]
	local self = Construct({
		discordClient = discordClient,
	}, BaseDiscordChannel.Prototype) :: any

	for key, value in channelData do
		self[key] = value
	end

	return self
end

export type BaseDiscordChannel = typeof(BaseDiscordChannel.Prototype) & {
	discordClient: any,

	id: string,
	type: number,

	name: string,
	description: string?,
}

return BaseDiscordChannel.Interface
