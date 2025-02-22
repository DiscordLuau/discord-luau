--[[
	Implementation of the Discord Action class in Luau

	https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object
]]

local apiTypes = require("../../../lune_packages/api_types")

local metadata = require("./metadata")

local Action = {}

Action.Interface = {}
Action.Prototype = {}

function Action.Prototype.sync(self: Action, actionData: apiTypes.AutomoderationActionObject)
	self.type = apiTypes.guild.ActionTypes[actionData.type]
	self.metadata = actionData.metadata and metadata.new(actionData.metadata)
end

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
