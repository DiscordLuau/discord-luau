--[[
	Implementation of the Discord Command Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

local apiTypes = require("@api-types/apiTypes")

local interactionBehaviour = require("@classes/interaction/behaviour/interaction")

-- selene: allow(unused_variable)
local state = require("@classes/state")

local Command = {}

Command.Interface = {}
Command.Prototype = {}
Command.Behaviours = {
	interactionBehaviour,
}

function Command.Prototype.sync(self: Command, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Command.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

function Command.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Command
	local self = setmetatable(
		{
			state = state,
		} :: Command,
		{ __index = Command.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Command = typeof(Command.Prototype) & interactionBehaviour.Interaction

return Command.Interface
