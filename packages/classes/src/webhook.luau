--[=[
	@class Classes.Webhook
	@__index Prototype

	Implementation of the Discord Webhook class in Luau

	https://discord.com/developers/docs/resources/webhook#webhook-object
]=]

local apiTypes = require("../lune_packages/api_types")

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
	--[=[
		@prop id string
		@within Classes.Webhook
		The unique identifier for this webhook.
	]=]
	self.id = webhookData.id

	--[=[
		@prop type apiTypes.WebhookType
		@within Classes.Webhook
		The type of webhook, indicating its source and behavior.
	]=]
	self.type = apiTypes.webhook.WebhookType[webhookData.type]

	--[=[
		@prop guildId string?
		@within Classes.Webhook
		The ID of the guild this webhook belongs to, if it's a server webhook.
	]=]
	self.guildId = webhookData.guild_id

	--[=[
		@prop channelId string?
		@within Classes.Webhook
		The ID of the channel this webhook is associated with.
	]=]
	self.channelId = webhookData.channel_id

	--[=[
		@prop user Classes.User?
		@within Classes.Webhook
		The user who created this webhook.
	]=]
	self.user = webhookData.user and user.new(webhookData.user)

	--[=[
		@prop name string?
		@within Classes.Webhook
		The name of the webhook.
	]=]
	self.name = webhookData.name

	--[=[
		@prop avatar string?
		@within Classes.Webhook
		The avatar hash of the webhook.
	]=]
	self.avatar = webhookData.avatar

	--[=[
		@prop token string?
		@within Classes.Webhook
		The token used to authenticate webhook requests.
	]=]
	self.token = webhookData.token

	--[=[
		@prop applicationId string?
		@within Classes.Webhook
		The ID of the application that created this webhook.
	]=]
	self.applicationId = webhookData.application_id

	--[=[
		@prop url string?
		@within Classes.Webhook
		The URL used to execute this webhook.
	]=]
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
