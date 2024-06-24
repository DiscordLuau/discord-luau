local Future = require("@Vendor/Future")

local Construct = require("@Utils/Construct")

local DiscordUser = require("@Objects/DiscordUser")
local DiscordApplication = require("@Objects/DiscordApplication")

local DiscordEndpoints = require("@Data/DiscordEndpoints")

local CacheType = require("@Enums/CacheType")

--[=[
	@class Objects.DiscordIntegration

	DiscordIntegration represents a guild integration.
]=]

--[=[
	@prop guildId string
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop id string
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop name string
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop type number
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop enabled boolean
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop syncing boolean?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop roleId string?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop enableEmoticons boolean?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop expireBehaviour number?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop expireGracePeriod number?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop user Objects.DiscordUser?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop account { id: string, name: string }?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop syncedAt string?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop subscriberCount number?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop revoked boolean?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop application Objects.Application?
	@within Objects.DiscordIntegration
]=]

--[=[
	@prop scopes { string }?
	@within Objects.DiscordIntegration
]=]

local DiscordIntegration = {}

DiscordIntegration.Prototype = {}
DiscordIntegration.Interface = {}

DiscordIntegration.Prototype.type = "DiscordIntegration"

--[=[
	Deletes the invite asynchronously.
	
	@method deleteAsync
	@return Vendor.Future<unknown> -- A future that resolves when the invite is deleted.
	@within Objects.DiscordIntegration
]=]
function DiscordIntegration.Prototype.deleteAsync(self: DiscordIntegration)
	return Future.try(function()
		return self.discordClient.discordGateway
			:deleteAsync(string.format(DiscordEndpoints.BotDeleteGuildIntegration, self.guildId, self.id))
			:await()
	end)
end

--[=[
	Creates a new instance of DiscordIntegration.
	
	@function new
	@param discordClient any -- The Discord client instance.
	@param integrationData table -- The data for the invite to be created.
	@return DiscordIntegration -- A new instance of DiscordIntegration.
	@within Objects.DiscordIntegration
]=]
function DiscordIntegration.Interface.new(
	discordClient: any,
	guildId: string,
	integrationData: {
		id: string,

		[string]: any,
	}
)
	local self = discordClient.discordCache:getDataOr(
		CacheType.DiscordIntegration,
		`{guildId}-{integrationData.id}`,
		function()
			return Construct({
				discordClient = discordClient,

				guildId = guildId,
			}, DiscordIntegration.Prototype)
		end
	)

	if integrationData.user then
		integrationData.user = DiscordUser.new(discordClient, integrationData.user)
	end

	if integrationData.application then
		integrationData.application = DiscordApplication.new(discordClient, integrationData.application)
	end

	for index, value in integrationData do
		self[index] = value
	end

	return self
end

export type DiscordIntegration = typeof(DiscordIntegration.Prototype) & {
	discordClient: any,
	guildId: string,

	id: string,
	name: string,
	type: number,
	enabled: boolean,
	syncing: boolean?,
	roleId: string?,
	enableEmoticons: boolean?,
	expireBehaviour: number?,
	expireGracePeriod: number?,
	user: DiscordUser.DiscordUser?,
	account: { id: string, name: string }?,
	syncedAt: string?,
	subscriberCount: number?,
	revoked: boolean?,
	application: DiscordApplication.DiscordApplication?,
	scopes: { string }?,
}

return DiscordIntegration.Interface
