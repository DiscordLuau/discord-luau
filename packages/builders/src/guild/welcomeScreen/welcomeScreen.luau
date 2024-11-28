--[[
	Implementation of discords WelcomeScreen object as a Luau builder.	

	https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen-json-params
]]

local WelcomeScreenChannel = require("./channel")

local WelcomeScreen = {}

WelcomeScreen.Prototype = {}
WelcomeScreen.Interface = {}

--[[
	Set weather the welcome screen is enabled or not.
]]
function WelcomeScreen.Prototype.setEnabled(self: WelcomeScreen, enabled: boolean): WelcomeScreen
	self.enabled = enabled

	return self
end

--[[
	Set the description of the welcome screen.
]]
function WelcomeScreen.Prototype.setDescription(self: WelcomeScreen, description: string): WelcomeScreen
	self.description = description

	return self
end

--[[
	Add an welcome screen channel to the welcome screen
]]
function WelcomeScreen.Prototype.addChannel(self: WelcomeScreen, channel: WelcomeScreenChannel.JSON): WelcomeScreen
	table.insert(self.welcomeChannels, channel)

	return self
end

--[[
	Responsible for building the WelcomeScreenObject JSON that can be parsed by the Discord API.
]]
function WelcomeScreen.Prototype.build(self: WelcomeScreen): JSON
	return {
		enabled = self.enabled,
		description = self.description,
		welcome_channels = self.welcomeChannels,
	}
end

--[[
	Responsible for creating a new WelcomeScreen.

	```lua
	
	```
]]
function WelcomeScreen.Interface.new(resource: {
	enabled: boolean?,
	description: string?,
	welcomeChannels: { WelcomeScreenChannel.JSON }?,
}?): WelcomeScreen
	local self = setmetatable(
		{
			welcomeChannels = {},
		} :: WelcomeScreen,
		{
			__index = WelcomeScreen.Prototype,
		}
	)

	if resource then
		if resource.enabled ~= nil then
			self:setEnabled(resource.enabled)
		end

		if resource.description then
			self:setDescription(resource.description)
		end

		if resource.welcomeChannels then
			for _, channel in resource.welcomeChannels do
				self:addChannel(channel)
			end
		end
	end

	return self
end

export type WelcomeScreen = typeof(WelcomeScreen.Prototype) & {
	enabled: boolean?,
	description: string?,
	welcomeChannels: { WelcomeScreenChannel.JSON },
}

export type JSON = typeof(WelcomeScreen.Prototype.build(nil :: any))

return WelcomeScreen.Interface
