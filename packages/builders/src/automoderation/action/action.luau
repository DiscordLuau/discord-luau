--[=[
	@class Builders.Action
	@__index Prototype

	Implementation of a discord automod action object as a luau builder.
]=]

local apiTypes = require("../../../lune_packages/api_types")
local metadata = require("./metadata")

local Action = {}

Action.Prototype = {}
Action.Interface = {}

--[=[
	@within Builders.Action

	Sets the type of the action.
]=]
function Action.Prototype.setType(self: Action, type: apiTypes.ActionTypes): Action
	self.type = type

	return self
end

--[=[
	@within Builders.Action

	Sets the action metadata.
]=]
function Action.Prototype.setMetadata(self: Action, metadata: metadata.JSON): Action
	self.metadata = metadata

	return self
end

--[=[
	@within Builders.Action

	Builds the action object.
]=]
function Action.Prototype.build(self: Action): JSON
	return {
		type = apiTypes.guild.ActionTypes[self.type],
		metadata = self.metadata,
	}
end

--[=[
	@within Builders.Action

	Responsible for creating a new Action.
]=]
function Action.Interface.new(resource: {
	type: apiTypes.ActionTypes?,
	metadata: metadata.JSON?,
}?): Action
	local self = setmetatable(
		{
			--[=[
				@prop type apiTypes.ActionTypes
				@within Builders.Action
				The type of action to perform when a rule is triggered.
			]=]
			type = nil,

			--[=[
				@prop metadata Builders.ActionMetadata
				@within Builders.Action
				Additional metadata needed during execution for this specific action type.
			]=]
			metadata = nil,
		} :: Action,
		{
			__index = Action.Prototype,
		}
	)

	if resource then
		if resource.type then
			self:setType(resource.type)
		end

		if resource.metadata then
			self:setMetadata(resource.metadata)
		end
	end

	return self
end

export type Action = typeof(Action.Prototype) & {
	type: apiTypes.ActionTypes,
	metadata: metadata.JSON?,
}

export type JSON = typeof(Action.Prototype.build(nil :: any))

return Action.Interface
