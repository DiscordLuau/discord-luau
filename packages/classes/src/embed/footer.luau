--[=[
	@class Classes.Footer
	@__index Prototype

	Implementation of the Discord Footer class in Luau

	https://discord.com/developers/docs/resources/message#embed-object-embed-footer-structure
]=]

local apiTypes = require("../../lune_packages/api_types")

local Footer = {}

Footer.Interface = {}
Footer.Prototype = {}

--[=[
	@within Classes.Footer
	@private

	Responsible for syncing data to this footer object. This is typically called by the API when this object is
	created or updated.
]=]
function Footer.Prototype.sync(self: Footer, footerData: apiTypes.EmbedFooterObject)
	--[=[
		@prop text string
		@within Classes.Footer
		The text content of the footer
	]=]
	self.text = footerData.text

	--[=[
		@prop iconUrl string?
		@within Classes.Footer
		The URL of the footer icon
	]=]
	self.iconUrl = footerData.icon_url

	--[=[
		@prop proxyIconUrl string?
		@within Classes.Footer
		The proxied URL of the footer icon
	]=]
	self.proxyIconUrl = footerData.proxy_icon_url
end

--[=[
	@within Classes.Footer
	@private

	Responsible for constructing this class.
]=]
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
