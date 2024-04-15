local Construct = require("../../Utils/Construct")

--[=[
	@class Internal.DiscordApplication

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordApplication = {}

DiscordApplication.Prototype = {}
DiscordApplication.Interface = {}

DiscordApplication.Prototype.type = "DiscordApplication"

function DiscordApplication.Interface.new(discordClient: any, applicationData: {
	id: string,
	flags: number
})
	return discordClient.discordCache:getDataOr(applicationData.id, function()
		return Construct({
			id = applicationData.id,
			flags = applicationData.flags,
	
			discordClient = discordClient
		}, DiscordApplication.Prototype)
	end)
end

export type DiscordApplication = typeof(DiscordApplication.Interface.new())

return DiscordApplication.Interface