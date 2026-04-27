--[=[
	@class Classes.Guild.VanityUrl
	@__index Prototype

	Implementation of the Discord VanityUrl class in Luau

	https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
]=]

--[=[
	@prop code string
	@within Classes.Guild.VanityUrl

	The unique code for this vanity URL. This code appears in the URL that users can use to join the guild.
]=]

--[=[
	@prop uses number
	@within Classes.Guild.VanityUrl

	The number of times this vanity URL has been used to join the guild.
]=]

local apiTypes = require("../../luau_packages/api_types")

local VanityUrl = {}

VanityUrl.Interface = {}
VanityUrl.Prototype = {}

--[=[
	@within Classes.Guild.VanityUrl
	@private

	Responsible for syncing data to this vanity URL object. This is typically called by the API when this object is
	created or updated.
]=]
function VanityUrl.Prototype.sync(self: VanityUrl, vanityUrlData: apiTypes.GuildVanityUrl)
	self.code = vanityUrlData.code

	self.uses = vanityUrlData.uses
end

--[=[
	@within Classes.Guild.VanityUrl
	@private

	Responsible for constructing this class.
]=]
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
