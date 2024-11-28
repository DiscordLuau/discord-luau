--[[
	Implementation of the Discord Author class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-author-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local Author = {}

Author.Interface = {}
Author.Prototype = {}

function Author.Prototype.sync(self: Author, authorData: apiTypes.EmbedAuthorObject)
	self.name = authorData.name
	self.url = authorData.url
	self.iconUrl = authorData.icon_url
	self.proxyIconUrl = authorData.proxy_icon_url
end

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
