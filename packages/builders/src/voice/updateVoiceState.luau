--[=[
	@class Builders.UpdateVoiceState
	@__index Prototype

	Implementation of Discord's Gateway Update Voice State (Op 4) payload as a Luau builder.

	https://discord.com/developers/docs/topics/gateway-events#update-voice-state
]=]

local UpdateVoiceState = {}

UpdateVoiceState.Prototype = {}
UpdateVoiceState.Interface = {}

function UpdateVoiceState.Prototype.setGuildId(self: UpdateVoiceState, guildId: string): UpdateVoiceState
	self.guildId = guildId
	return self
end

function UpdateVoiceState.Prototype.setChannelId(self: UpdateVoiceState, channelId: string?): UpdateVoiceState
	self.channelId = channelId
	return self
end

function UpdateVoiceState.Prototype.setSelfMute(self: UpdateVoiceState, selfMute: boolean): UpdateVoiceState
	self.selfMute = selfMute
	return self
end

function UpdateVoiceState.Prototype.setSelfDeaf(self: UpdateVoiceState, selfDeaf: boolean): UpdateVoiceState
	self.selfDeaf = selfDeaf
	return self
end

function UpdateVoiceState.Prototype.build(self: UpdateVoiceState): JSON
	assert(self.guildId, "UpdateVoiceState is missing a guild_id")
	assert(self.selfMute ~= nil, "UpdateVoiceState is missing self_mute")
	assert(self.selfDeaf ~= nil, "UpdateVoiceState is missing self_deaf")

	return {
		guild_id = self.guildId,
		channel_id = self.channelId,
		self_mute = self.selfMute,
		self_deaf = self.selfDeaf,
	}
end

function UpdateVoiceState.Interface.new(resource: {
	guildId: string?,
	channelId: string?,
	selfMute: boolean?,
	selfDeaf: boolean?,
}?): UpdateVoiceState
	local self = setmetatable({} :: UpdateVoiceState, { __index = UpdateVoiceState.Prototype })

	if resource then
		if resource.guildId then
			self:setGuildId(resource.guildId)
		end
		if resource.channelId ~= nil then
			self:setChannelId(resource.channelId)
		end
		if resource.selfMute ~= nil then
			self:setSelfMute(resource.selfMute)
		end
		if resource.selfDeaf ~= nil then
			self:setSelfDeaf(resource.selfDeaf)
		end
	end

	return self
end

export type UpdateVoiceState = typeof(UpdateVoiceState.Prototype) & {
	guildId: string?,
	channelId: string?,
	selfMute: boolean?,
	selfDeaf: boolean?,
}

export type JSON = typeof(UpdateVoiceState.Prototype.build(nil :: any))

return UpdateVoiceState.Interface
