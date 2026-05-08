--[=[
	@class Builders.Webhook
	@__index Prototype

	Implementation of Discord's Create/Modify Webhook params as a Luau builder.

	https://discord.com/developers/docs/resources/webhook#create-webhook-json-params
]=]

local Webhook = {}

Webhook.Prototype = {}
Webhook.Interface = {}

function Webhook.Prototype.setName(self: Webhook, name: string): Webhook
	assert(#name >= 1 and #name <= 80, "Webhook name must be between 1 and 80 characters")
	assert(name ~= "clyde", "Webhook name cannot be 'clyde'")
	self.name = name
	return self
end

function Webhook.Prototype.setAvatar(self: Webhook, avatarDataUri: string?): Webhook
	self.avatar = avatarDataUri
	return self
end

function Webhook.Prototype.build(self: Webhook): JSON
	assert(self.name, "Webhook is missing a name")

	return {
		name = self.name,
		avatar = self.avatar,
	}
end

function Webhook.Interface.new(resource: {
	name: string?,
	avatar: string?,
}?): Webhook
	local self = setmetatable({} :: Webhook, { __index = Webhook.Prototype })

	if resource then
		if resource.name then
			self:setName(resource.name)
		end
		if resource.avatar ~= nil then
			self:setAvatar(resource.avatar)
		end
	end

	return self
end

export type Webhook = typeof(Webhook.Prototype) & {
	name: string?,
	avatar: string?,
}

export type JSON = typeof(Webhook.Prototype.build(nil :: any))

return Webhook.Interface
