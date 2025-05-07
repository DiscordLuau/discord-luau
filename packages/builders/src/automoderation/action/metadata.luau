--[=[
	@class Builders.ActionMetadata
	@__index Prototype

	Implementation of a discord automoderation action metadata object as a luau builder.
]=]

local apiTypes = require("../../../lune_packages/api_types")

local ActionMetadata = {}

ActionMetadata.Prototype = {}
ActionMetadata.Interface = {}

--[=[
	@within Builders.ActionMetadata

	Sets the ID of the channel where the action should be taken.
]=]
function ActionMetadata.Prototype.setChannelId(self: ActionMetadata, channelId: apiTypes.Snowflake): ActionMetadata
	self.channelId = channelId

	return self
end

--[=[
	@within Builders.ActionMetadata

	Sets the duration of the action in seconds.
]=]
function ActionMetadata.Prototype.setDurationSeconds(self: ActionMetadata, durationSeconds: number): ActionMetadata
	self.durationSeconds = durationSeconds

	return self
end

--[=[
	@within Builders.ActionMetadata

	Sets a custom message to be sent with the action.
]=]
function ActionMetadata.Prototype.setCustomMessage(self: ActionMetadata, customMessage: string): ActionMetadata
	self.customMessage = customMessage

	return self
end

--[=[
	@within Builders.ActionMetadata

	Builds the action metadata object.
]=]
function ActionMetadata.Prototype.build(self: ActionMetadata): JSON
	return {
		channel_id = self.channelId,
		duration_seconds = self.durationSeconds,
		custom_message = self.customMessage,
	}
end

--[=[
	@within Builders.ActionMetadata

	Responsible for creating a new ActionMetadata.

	```luau
	local metadata = ActionMetadata.new({
		channelId = "123456789",
		durationSeconds = 300,
		customMessage = "Action taken due to rule violation"
	})
	```
]=]
function ActionMetadata.Interface.new(resource: {
	channelId: apiTypes.Snowflake?,
	durationSeconds: number?,
	customMessage: string?,
}?): ActionMetadata
	local self = setmetatable(
		{
			--[=[
				@prop channelId string
				@within Builders.ActionMetadata
				The ID of the channel where the action should be taken.
			]=]
			channelId = nil,

			--[=[
				@prop durationSeconds number
				@within Builders.ActionMetadata
				The duration of the action in seconds.
			]=]
			durationSeconds = nil,

			--[=[
				@prop customMessage string?
				@within Builders.ActionMetadata
				A custom message that will be shown to members when the action is taken.
			]=]
			customMessage = nil,
		} :: ActionMetadata,
		{
			__index = ActionMetadata.Prototype,
		}
	)

	if resource then
		if resource.channelId then
			self:setChannelId(resource.channelId)
		end

		if resource.durationSeconds then
			self:setDurationSeconds(resource.durationSeconds)
		end

		if resource.customMessage then
			self:setCustomMessage(resource.customMessage)
		end
	end

	return self
end

export type ActionMetadata = typeof(ActionMetadata.Prototype) & {
	channelId: apiTypes.Snowflake,
	durationSeconds: number,
	customMessage: string?,
}

export type JSON = typeof(ActionMetadata.Prototype.build(nil :: any))

return ActionMetadata.Interface
