--[[
	Implementation of discords Footer object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#embed-object-embed-footer-structure
]]

local Footer = {}

Footer.Prototype = {}
Footer.Interface = {}

--[[
	
]]
function Footer.Prototype.setText(self: Footer, text: string): Footer
	assert(#text <= 2048, "Name must be less than 2048 characters")
	assert(#text > 1, "Name must be greater than 1 characters")

	self.text = text

	return self
end

--[[
	
]]
function Footer.Prototype.setIcon(self: Footer, iconUrl: string, proxyIconUrl: string?): Footer
	self.iconUrl = iconUrl
	self.proxyIconUrl = proxyIconUrl

	return self
end

--[[
	Responsible for building the Footer JSON that can be parsed by the Discord API.
]]
function Footer.Prototype.build(self: Footer): JSON
	assert(self.text, `Footer must have a text`)

	return {
		text = self.text,
		icon_url = self.iconUrl,
		proxy_icon_url = self.proxyIconUrl,
	}
end

--[[
	Responsible for creating a new Footer.

	```lua
	
	```
]]
function Footer.Interface.new(resource: {
	text: string?,
	iconUrl: string?,
	proxyIconUrl: string?,
}?): Footer
	local self = setmetatable({} :: Footer, {
		__index = Footer.Prototype,
	})

	if resource then
		if resource.text then
			self:setText(resource.text)
		end

		if resource.iconUrl then
			self:setIcon(resource.iconUrl, resource.proxyIconUrl)
		end
	end

	return self
end

export type Footer = typeof(Footer.Prototype) & {
	text: string?,
	iconUrl: string?,
	proxyIconUrl: string?,
}

export type JSON = typeof(Footer.Prototype.build({} :: any))

return Footer.Interface
