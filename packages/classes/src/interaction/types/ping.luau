--[[
	Implementation of the Discord Ping Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

local apiTypes = require("@api-types/apiTypes")

local interactionBehaviour = require("@classes/interaction/behaviour/interaction")

-- selene: allow(unused_variable)
local state = require("@classes/state")

local Ping = {}

Ping.Interface = {}
Ping.Prototype = {}
Ping.Behaviours = {
	interactionBehaviour,
}

function Ping.Prototype.sync(self: Ping, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Ping.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

function Ping.Interface.new(state: state.State, interactionData: apiTypes.InteractionObject): Ping
	local self = setmetatable(
		{
			state = state,
		} :: Ping,
		{ __index = Ping.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Ping = typeof(Ping.Prototype) & interactionBehaviour.Interaction

return Ping.Interface
