--[[
	Implementation of the Discord Integration Application class in Luau

	https://discord.com/developers/docs/resources/guild#integration-application-object
]]

local apiTypes = require("../../../lune_packages/api_types")

local user = require("../../user")

local Application = {}

Application.Interface = {}
Application.Prototype = {}

function Application.Prototype.sync(self: Application, applicationData: apiTypes.IntegrationApplicationObject)
	self.id = applicationData.id
	self.name = applicationData.name
	self.icon = applicationData.icon
	self.description = applicationData.description
	self.bot = applicationData.bot and user.new(applicationData.bot)
end

function Application.Interface.new(applicationData: apiTypes.IntegrationApplicationObject): Application
	local self = setmetatable({} :: Application, { __index = Application.Prototype })

	self:sync(applicationData)

	return self
end

export type Application = typeof(Application.Prototype) & {
	id: string,
	name: string,
	icon: string?,
	description: string,
	bot: user.User?,
}

return Application.Interface
