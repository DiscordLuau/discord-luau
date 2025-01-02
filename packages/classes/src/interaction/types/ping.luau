--[[
	Implementation of the Discord Ping Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]]

-- selene: allow(unused_variable)
local state = require("../../../lune_packages/state")
local apiTypes = require("../../../lune_packages/api_types")
local rest = require("../../../lune_packages/rest")
local future = require("../../../luau_packages/future")

local interactionBehaviour = require("../behaviour/interaction")

local Ping = {}

Ping.Interface = {}
Ping.Prototype = {}
Ping.Behaviours = {
	interactionBehaviour,
}

--[[
	acknowledge an interaction ping
]]
function Ping.Prototype.pongAsync(self: Ping): future.Future<string, nil>
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local status, response = rest.interaction
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = 1,
				data = {},
			}, {
				withResponse = false,
			})
			:await()

		assert(status == "Fulfilled", tostring(response))
	end)
end

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
