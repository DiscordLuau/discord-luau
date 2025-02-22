--[[
	Implementation of the Discord Webhook class in Luau

	https://discord.com/developers/docs/resources/webhook#webhook-object
]]

local apiTypes = require("../lune_packages/api_types")

local user = require("./user")

local Webhook = {}

Webhook.Interface = {}
Webhook.Prototype = {}

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
