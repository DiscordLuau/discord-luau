--[=[
	@class Builders.ExecuteWebhook
	@__index Prototype

	Implementation of Discord's Execute Webhook params as a Luau builder.

	https://discord.com/developers/docs/resources/webhook#execute-webhook-jsonform-params
]=]

local embed = require("../embed/embed")
local allowedMention = require("../message/allowedMention")
local poll = require("../message/poll/poll")

local ExecuteWebhook = {}

ExecuteWebhook.Prototype = {}
ExecuteWebhook.Interface = {}

function ExecuteWebhook.Prototype.setContent(self: ExecuteWebhook, content: string): ExecuteWebhook
	assert(#content <= 2000, "Content must be at most 2000 characters")
	self.content = content
	return self
end

function ExecuteWebhook.Prototype.setUsername(self: ExecuteWebhook, username: string): ExecuteWebhook
	self.username = username
	return self
end

function ExecuteWebhook.Prototype.setAvatarUrl(self: ExecuteWebhook, avatarUrl: string): ExecuteWebhook
	self.avatarUrl = avatarUrl
	return self
end

function ExecuteWebhook.Prototype.setTTS(self: ExecuteWebhook, tts: boolean): ExecuteWebhook
	self.tts = tts
	return self
end

function ExecuteWebhook.Prototype.addEmbed(self: ExecuteWebhook, embedData: embed.JSON): ExecuteWebhook
	local embeds = self.embeds or {}
	assert(#embeds < 10, "Webhooks cannot have more than 10 embeds")
	table.insert(embeds, embedData)
	self.embeds = embeds
	return self
end

function ExecuteWebhook.Prototype.setAllowedMentions(
	self: ExecuteWebhook,
	mentions: allowedMention.JSON
): ExecuteWebhook
	self.allowedMentions = mentions
	return self
end

function ExecuteWebhook.Prototype.addComponent(self: ExecuteWebhook, component: { [string]: any }): ExecuteWebhook
	local components = self.components or {}
	table.insert(components, component)
	self.components = components
	return self
end

function ExecuteWebhook.Prototype.addAttachment(
	self: ExecuteWebhook,
	id: number,
	filename: string,
	description: string?
): ExecuteWebhook
	local attachments = self.attachments or {}
	table.insert(attachments, { id = id, filename = filename, description = description })
	self.attachments = attachments
	return self
end

function ExecuteWebhook.Prototype.setFlags(self: ExecuteWebhook, flags: number): ExecuteWebhook
	self.flags = flags
	return self
end

function ExecuteWebhook.Prototype.setThreadName(self: ExecuteWebhook, threadName: string): ExecuteWebhook
	self.threadName = threadName
	return self
end

function ExecuteWebhook.Prototype.setAppliedTags(self: ExecuteWebhook, tags: { string }): ExecuteWebhook
	self.appliedTags = tags
	return self
end

function ExecuteWebhook.Prototype.setPoll(self: ExecuteWebhook, pollData: poll.JSON): ExecuteWebhook
	self.poll = pollData
	return self
end

function ExecuteWebhook.Prototype.build(self: ExecuteWebhook): JSON
	local hasContent = self.content ~= nil
	local hasEmbeds = self.embeds ~= nil and #self.embeds > 0
	local hasPoll = self.poll ~= nil
	local hasComponents = self.components ~= nil and #self.components > 0

	assert(
		hasContent or hasEmbeds or hasPoll or hasComponents,
		"ExecuteWebhook requires at least one of: content, embeds, poll, components"
	)

	return {
		content = self.content,
		username = self.username,
		avatar_url = self.avatarUrl,
		tts = self.tts,
		embeds = self.embeds,
		allowed_mentions = self.allowedMentions,
		components = self.components,
		attachments = self.attachments,
		flags = self.flags,
		thread_name = self.threadName,
		applied_tags = self.appliedTags,
		poll = self.poll,
	}
end

function ExecuteWebhook.Interface.new(resource: {
	content: string?,
	username: string?,
	avatarUrl: string?,
	tts: boolean?,
	embeds: { embed.JSON }?,
	allowedMentions: allowedMention.JSON?,
	components: { { [string]: any } }?,
	attachments: { { id: number, filename: string, description: string? } }?,
	flags: number?,
	threadName: string?,
	appliedTags: { string }?,
	poll: poll.JSON?,
}?): ExecuteWebhook
	local self = setmetatable({} :: ExecuteWebhook, { __index = ExecuteWebhook.Prototype })

	if resource then
		if resource.content then
			self:setContent(resource.content)
		end
		if resource.username then
			self:setUsername(resource.username)
		end
		if resource.avatarUrl then
			self:setAvatarUrl(resource.avatarUrl)
		end
		if resource.tts ~= nil then
			self:setTTS(resource.tts)
		end
		if resource.embeds then
			for _, e in resource.embeds do
				self:addEmbed(e)
			end
		end
		if resource.allowedMentions then
			self:setAllowedMentions(resource.allowedMentions)
		end
		if resource.components then
			for _, c in resource.components do
				self:addComponent(c)
			end
		end
		if resource.attachments then
			for _, a in resource.attachments do
				self:addAttachment(a.id, a.filename, a.description)
			end
		end
		if resource.flags then
			self:setFlags(resource.flags)
		end
		if resource.threadName then
			self:setThreadName(resource.threadName)
		end
		if resource.appliedTags then
			self:setAppliedTags(resource.appliedTags)
		end
		if resource.poll then
			self:setPoll(resource.poll)
		end
	end

	return self
end

export type ExecuteWebhook = typeof(ExecuteWebhook.Prototype) & {
	content: string?,
	username: string?,
	avatarUrl: string?,
	tts: boolean?,
	embeds: { embed.JSON }?,
	allowedMentions: allowedMention.JSON?,
	components: { { [string]: any } }?,
	attachments: { { id: number, filename: string, description: string? } }?,
	flags: number?,
	threadName: string?,
	appliedTags: { string }?,
	poll: poll.JSON?,
}

export type JSON = typeof(ExecuteWebhook.Prototype.build(nil :: any))

return ExecuteWebhook.Interface
