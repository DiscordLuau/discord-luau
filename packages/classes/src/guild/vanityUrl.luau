--[[
	Implementation of the Discord VanityUrl class in Luau

	https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
]]

local apiTypes = require("../../lune_packages/api_types")

local VanityUrl = {}

VanityUrl.Interface = {}
VanityUrl.Prototype = {}

function VanityUrl.Prototype.sync(self: VanityUrl, vanityUrlData: apiTypes.GuildVanityUrl)
	self.code = vanityUrlData.code
	self.uses = vanityUrlData.uses
end

function VanityUrl.Interface.new(vanityUrlData: apiTypes.GuildVanityUrl): VanityUrl
	local self = setmetatable({} :: VanityUrl, { __index = VanityUrl.Prototype })

	self:sync(vanityUrlData)

	return self
end

export type VanityUrl = typeof(VanityUrl.Prototype) & {
	code: string,
	uses: number,
}

return VanityUrl.Interface
