--[=[
	@class Classes.Provider
	@__index Prototype

	Implementation of the Discord Provider class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-provider-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local Provider = {}

Provider.Interface = {}
Provider.Prototype = {}

--[=[
	@within Classes.Provider
	@private

	Responsible for syncing data to this provider object. This is typically called by the API when this object is
	created or updated.
]=]
function Provider.Prototype.sync(self: Provider, providerData: apiTypes.EmbedProviderObject)
	--[=[
		@prop name string?
		@within Classes.Provider

		The name of the provider
	]=]
	self.name = providerData.name

	--[=[
		@prop url string?
		@within Classes.Provider

		The URL of the provider
	]=]
	self.url = providerData.url
end

--[=[
	@within Classes.Provider
	@private

	Responsible for constructing this class.
]=]
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
