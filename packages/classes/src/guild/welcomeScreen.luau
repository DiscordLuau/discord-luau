--[[
	Implementation of the Discord WelcomeScreen class in Luau

	https://discord.com/developers/docs/resources/guild#welcome-screen-object
]]

local apiTypes = require("../../lune_packages/api_types")

local welcomeScreenChannel = require("./welcomeScreenChannel")

local WelcomeScreen = {}

WelcomeScreen.Interface = {}
WelcomeScreen.Prototype = {}

function WelcomeScreen.Prototype.sync(self: WelcomeScreen, welcomeScreenData: apiTypes.WelcomeScreenObject_)
	local welcomeChannelArray = {}

	for _, welcomeChannelData in welcomeScreenData.welcome_channels do
		table.insert(welcomeChannelArray, welcomeScreenChannel.new(welcomeChannelData))
	end

	self.welcomeChannels = welcomeChannelArray

	self.description = welcomeScreenData.description
end

function WelcomeScreen.Interface.new(welcomeScreenData: apiTypes.WelcomeScreenObject_): WelcomeScreen
	local self = setmetatable({} :: WelcomeScreen, { __index = WelcomeScreen.Prototype })

	self:sync(welcomeScreenData)

	return self
end

export type WelcomeScreen = typeof(WelcomeScreen.Prototype) & {
	description: string?,
	welcomeChannels: { welcomeScreenChannel.WelcomeScreenChannel },
}

return WelcomeScreen.Interface
