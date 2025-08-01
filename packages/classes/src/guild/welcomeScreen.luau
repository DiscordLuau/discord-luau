--[=[
	@class Classes.WelcomeScreen
	@__index Prototype

	Implementation of the Discord WelcomeScreen class in Luau

	https://discord.com/developers/docs/resources/guild#welcome-screen-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local welcomeScreenChannel = require("./welcomeScreenChannel")

local WelcomeScreen = {}

WelcomeScreen.Interface = {}
WelcomeScreen.Prototype = {}

--[=[
	@within Classes.WelcomeScreen
	@private

	Responsible for syncing data to this welcome screen object. This is typically called by the API when this object is
	created or updated.
]=]
function WelcomeScreen.Prototype.sync(self: WelcomeScreen, welcomeScreenData: apiTypes.WelcomeScreenObject)
	--[=[
		@prop welcomeChannels { Classes.WelcomeScreenChannel }
		@within Classes.WelcomeScreen

		An array of welcome screen channel objects linked to the guild's welcome screen. These channels are shown to new members
		when they join the guild.
	]=]
	local welcomeChannelArray = {}

	for _, welcomeChannelData in welcomeScreenData.welcome_channels do
		table.insert(welcomeChannelArray, welcomeScreenChannel.new(welcomeChannelData))
	end

	self.welcomeChannels = welcomeChannelArray

	--[=[
		@prop description string?
		@within Classes.WelcomeScreen

		The server description shown in the welcome screen. This description provides new members with information about
		the guild when they first join.
	]=]
	self.description = welcomeScreenData.description
end

--[=[
	@within Classes.WelcomeScreen
	@private

	Responsible for constructing this class.
]=]
function WelcomeScreen.Interface.new(welcomeScreenData: apiTypes.WelcomeScreenObject): WelcomeScreen
	local self = setmetatable({} :: WelcomeScreen, { __index = WelcomeScreen.Prototype })

	self:sync(welcomeScreenData)

	return self
end

export type WelcomeScreen = typeof(WelcomeScreen.Prototype) & {
	description: string?,
	welcomeChannels: { welcomeScreenChannel.WelcomeScreenChannel },
}

return WelcomeScreen.Interface
