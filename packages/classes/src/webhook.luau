--[=[
	@class Classes.Webhook
	@__index Prototype

	Implementation of the Discord Webhook class in Luau

	https://discord.com/developers/docs/resources/webhook#webhook-object
]=]

--[=[
	@prop id string
	@within Classes.Webhook
	The unique identifier for this webhook.
]=]

--[=[
	@prop type apiTypes.WebhookType
	@within Classes.Webhook
	The type of webhook, indicating its source and behavior.
]=]

--[=[
	@prop guildId string?
	@within Classes.Webhook
	The ID of the guild this webhook belongs to, if it's a server webhook.
]=]

--[=[
	@prop channelId string?
	@within Classes.Webhook
	The ID of the channel this webhook is associated with.
]=]

--[=[
	@prop user Classes.User?
	@within Classes.Webhook
	The user who created this webhook.
]=]

--[=[
	@prop name string?
	@within Classes.Webhook
	The name of the webhook.
]=]

--[=[
	@prop avatar string?
	@within Classes.Webhook
	The avatar hash of the webhook.
]=]

--[=[
	@prop token string?
	@within Classes.Webhook
	The token used to authenticate webhook requests.
]=]

--[=[
	@prop applicationId string?
	@within Classes.Webhook
	The ID of the application that created this webhook.
]=]

--[=[
	@prop url string?
	@within Classes.Webhook
	The URL used to execute this webhook.
]=]

local apiTypes = require("../luau_packages/api_types")

local user = require("./user")

local Webhook = {}

Webhook.Interface = {}
Webhook.Prototype = {}

--[=[
	@within Classes.Webhook
	@private

	Responsible for syncing data to this webhook object. This is typically called by the API when this object is
	created or updated.
]=]
function Webhook.Prototype.sync(self: Webhook, webhookData: apiTypes.WebhookObject)
	self.id = webhookData.id

	self.type = apiTypes.webhook.WebhookType[webhookData.type]

	self.guildId = webhookData.guild_id

	self.channelId = webhookData.channel_id

	self.user = webhookData.user and user.new(webhookData.user)

	self.name = webhookData.name

	self.avatar = webhookData.avatar

	self.token = webhookData.token

	self.applicationId = webhookData.application_id

	self.url = webhookData.url
end

--[=[
	@within Classes.Webhook
	@private

	Responsible for constructing this class.
]=]
function Webhook.Interface.new(webhookData: apiTypes.WebhookObject): Webhook
	local self = setmetatable({} :: Webhook, { __index = Webhook.Prototype })

	if webhookData then
		self:sync(webhookData)
	end

	return self
end

export type Webhook = typeof(Webhook.Prototype) & {
	id: apiTypes.Snowflake,
	type: apiTypes.WebhookType,
	guildId: apiTypes.Snowflake?,
	channelId: apiTypes.Snowflake?,
	user: user.User?,
	name: string?,
	avatar: string?,
	token: string?,
	applicationId: apiTypes.Snowflake?,
	url: string?,
}

return Webhook.Interface
