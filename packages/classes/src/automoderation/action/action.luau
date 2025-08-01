--[=[
	@class Classes.Action
	@__index Prototype

	Implementation of the Discord Action class in Luau

	https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object
]=]

local apiTypes = require("../../../lune_packages/api_types")

local metadata = require("./metadata")

local Action = {}

Action.Interface = {}
Action.Prototype = {}

--[=[
	@within Classes.Action
	@private

	Responsible for syncing data to this action object. This is typically called by the API when this object is
	created or updated.
]=]
function Action.Prototype.sync(self: Action, actionData: apiTypes.AutomoderationActionObject)
	--[=[
		@prop type apiTypes.ActionTypes
		@within Classes.Action

		The type of action to take when a rule is triggered. This can be one of the following:
		* BLOCK_MESSAGE - Block the message from being sent
		* SEND_ALERT_MESSAGE - Send an alert message to a specified channel
		* TIMEOUT - Timeout the user for a specified duration
	]=]
	self.type = apiTypes.guild.ActionTypes[actionData.type]

	--[=[
		@prop metadata Classes.ActionMetadata?
		@within Classes.Action

		Additional metadata needed during execution for this specific action type. Different action types may require different metadata properties.
		Only present when an action requires additional configuration.
	]=]
	self.metadata = actionData.metadata and metadata.new(actionData.metadata)
end

--[=[
	@within Classes.Action
	@private

	Responsible for constructing this class.
]=]
function Action.Interface.new(actionData: apiTypes.AutomoderationActionObject): Action
	local self = setmetatable({} :: Action, { __index = Action.Prototype })

	self:sync(actionData)

	return self
end

export type Action = typeof(Action.Prototype) & {
	type: apiTypes.ActionTypes,
	metadata: metadata.ActionMetadata?,
}

return Action.Interface
