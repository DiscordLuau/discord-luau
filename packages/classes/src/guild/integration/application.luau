--[=[
	@class Classes.Guild.IntegrationApplication
	@__index Prototype

	Implementation of the Discord Integration Application class in Luau

	https://discord.com/developers/docs/resources/guild#integration-application-object
]=]

--[=[
	@prop id string
	@within Classes.Guild.IntegrationApplication

	The unique identifier for this application
]=]

--[=[
	@prop name string
	@within Classes.Guild.IntegrationApplication

	The name of the application
]=]

--[=[
	@prop icon string?
	@within Classes.Guild.IntegrationApplication

	The icon hash of the application, if one exists
]=]

--[=[
	@prop description string
	@within Classes.Guild.IntegrationApplication

	The description of the application
]=]

--[=[
	@prop bot Classes.User?
	@within Classes.Guild.IntegrationApplication

	The bot user associated with this application, if it is a bot application
]=]

local apiTypes = require("../../../luau_packages/api_types")

local user = require("../../user")

local Application = {}

Application.Interface = {}
Application.Prototype = {}

--[=[
	@within Classes.Guild.IntegrationApplication
	@private

	Responsible for syncing data to this application object. This is typically called by the API when this object is
	created or updated.
]=]
function Application.Prototype.sync(self: Application, applicationData: apiTypes.IntegrationApplicationObject)
	self.id = applicationData.id

	self.name = applicationData.name

	self.icon = applicationData.icon

	self.description = applicationData.description

	self.bot = applicationData.bot and user.new(applicationData.bot)
end

--[=[
	@within Classes.Guild.IntegrationApplication
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
