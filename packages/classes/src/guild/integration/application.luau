--[=[
	@class Classes.Application
	@__index Prototype

	Implementation of the Discord Integration Application class in Luau

	https://discord.com/developers/docs/resources/guild#integration-application-object
]=]

local apiTypes = require("../../../lune_packages/api_types")

local user = require("../../user")

local Application = {}

Application.Interface = {}
Application.Prototype = {}

--[=[
	@within Classes.Application
	@private

	Responsible for syncing data to this application object. This is typically called by the API when this object is
	created or updated.
]=]
function Application.Prototype.sync(self: Application, applicationData: apiTypes.IntegrationApplicationObject)
	--[=[
		@prop id string
		@within Classes.Application

		The unique identifier for this application
	]=]
	self.id = applicationData.id

	--[=[
		@prop name string
		@within Classes.Application

		The name of the application
	]=]
	self.name = applicationData.name

	--[=[
		@prop icon string?
		@within Classes.Application

		The icon hash of the application, if one exists
	]=]
	self.icon = applicationData.icon

	--[=[
		@prop description string
		@within Classes.Application

		The description of the application
	]=]
	self.description = applicationData.description

	--[=[
		@prop bot Classes.User?
		@within Classes.Application

		The bot user associated with this application, if it is a bot application
	]=]
	self.bot = applicationData.bot and user.new(applicationData.bot)
end

--[=[
	@within Classes.Application
	@private

	Responsible for constructing this class.
]=]
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
