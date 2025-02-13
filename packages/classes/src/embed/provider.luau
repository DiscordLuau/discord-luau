--[[
	Implementation of the Discord Provider class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-provider-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local Provider = {}

Provider.Interface = {}
Provider.Prototype = {}

function Provider.Prototype.sync(self: Provider, providerData: apiTypes.EmbedProviderObject)
	self.name = providerData.name
	self.url = providerData.url
end

function Provider.Interface.new(providerData: apiTypes.EmbedProviderObject): Provider
	local self = setmetatable({} :: Provider, { __index = Provider.Prototype })

	self:sync(providerData)

	return self
end

export type Provider = typeof(Provider.Prototype) & {
	name: string?,
	url: string?,
}

return Provider.Interface
