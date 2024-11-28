--[[
	Implementation of the Discord Footer class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-footer-structure
]]

local apiTypes = require("../../lune_packages/api_types")

local Footer = {}

Footer.Interface = {}
Footer.Prototype = {}

function Footer.Prototype.sync(self: Footer, footerData: apiTypes.EmbedFooterObject)
	self.text = footerData.text
	self.iconUrl = footerData.icon_url
	self.proxyIconUrl = footerData.proxy_icon_url
end

function Footer.Interface.new(footerData: apiTypes.EmbedFooterObject): Footer
	local self = setmetatable({} :: Footer, { __index = Footer.Prototype })

	self:sync(footerData)

	return self
end

export type Footer = typeof(Footer.Prototype) & {
	text: string,
	iconUrl: string?,
	proxyIconUrl: string?,
}

return Footer.Interface
