--[=[
	@class Classes.Author
	@__index Prototype

	Implementation of the Discord Author class in Luau. This class represents the author of a Discord embed, which can include a name, URL, and icon.

	https://discord.com/developers/docs/resources/message#embed-object-embed-author-structure
]=]

--[=[
	@prop name string
	@within Classes.Author
	The name of the author.
]=]

--[=[
	@prop url string?
	@within Classes.Author
	The URL of the author's profile or website.
]=]

--[=[
	@prop iconUrl string?
	@within Classes.Author
	The URL of the author's icon.
]=]

--[=[
	@prop proxyIconUrl string?
	@within Classes.Author
	The proxied URL of the author's icon.
]=]

local apiTypes = require("../../luau_packages/api_types")

local Author = {}

Author.Interface = {}
Author.Prototype = {}

--[=[
	@within Classes.Author
	@private

	Responsible for syncing data to this author object. This is typically called by the API when this object is
	created or updated.
]=]
function Author.Prototype.sync(self: Author, authorData: apiTypes.EmbedAuthorObject)
	self.name = authorData.name

	self.url = authorData.url

	self.iconUrl = authorData.icon_url

	self.proxyIconUrl = authorData.proxy_icon_url
end

--[=[
	@within Classes.Author
	@private

	Responsible for constructing this class.
]=]
function Author.Interface.new(authorData: apiTypes.EmbedAuthorObject): Author
	local self = setmetatable({} :: Author, { __index = Author.Prototype })

	self:sync(authorData)

	return self
end

export type Author = typeof(Author.Prototype) & {
	name: string,
	url: string?,
	iconUrl: string?,
	proxyIconUrl: string?,
}

return Author.Interface
