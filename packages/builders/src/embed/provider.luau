--[=[
	@class Builders.Provider
	@__index Prototype

	Implementation of discords Provider object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#embed-object-embed-provider-structure
]=]

local Provider = {}

Provider.Prototype = {}
Provider.Interface = {}

--[=[
	@within Builders.Provider

	Set the image url for this embed.
]=]
function Provider.Prototype.setName(self: Provider, name: string): Provider
	assert(#name <= 256, "Name must be less than 256 characters")
	assert(#name > 1, "Name must be greater than 1 characters")

	self.name = name

	return self
end

--[=[
	@within Builders.Provider

	Set the image height for this embed.
]=]
function Provider.Prototype.setUrl(self: Provider, url: string): Provider
	self.url = url

	return self
end

--[=[
	@within Builders.Provider

	Responsible for building the Provider JSON that can be parsed by the Discord API.
]=]
function Provider.Prototype.build(self: Provider): JSON
	return {
		name = self.name,
		url = self.url,
	}
end

--[=[
	@within Builders.Provider

	Responsible for creating a new Provider.
]=]
function Provider.Interface.new(resource: {
	name: string?,
	url: string?,
}?): Provider
	local self = setmetatable(
		{
			--[=[
				@prop name string?
				@within Builders.Provider
				The name of the provider.
			]=]
			name = nil,

			--[=[
				@prop url string?
				@within Builders.Provider
				The url of the provider.
			]=]
			url = nil,
		} :: Provider,
		{
			__index = Provider.Prototype,
		}
	)

	if resource then
		if resource.name then
			self:setName(resource.name)
		end

		if resource.url then
			self:setUrl(resource.url)
		end
	end

	return self
end

export type Provider = typeof(Provider.Prototype) & {
	name: string?,
	url: string?,
}

export type JSON = typeof(Provider.Prototype.build({} :: any))

return Provider.Interface
