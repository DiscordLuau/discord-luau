--[=[
	@class Classes.Ping
	@__index Prototype

	Implementation of the Discord Ping Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-structure
]=]

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

--[=[
	@within Classes.Ping
	
	Acknowledge an interaction ping
]=]
function Ping.Prototype.pongAsync(self: Ping)
	local request = self.state.rest:newRequest()

	return future.Future.new(function()
		local response = rest.interaction
			.createInteractionResponseAsync(request, self.id, self.token, {
				type = 1,
				data = {},
			}, {
				withResponse = false,
			})
			:await()

		assert(response:isOk(), tostring(response:unwrapErr()))

		return nil
	end) :: future.FutureLike<string, nil>
end

--[=[
	@within Classes.Ping
	@private

	Responsible for syncing data to this interaction object. This is typically called by the API when this object is
	created or updated.
]=]
function Ping.Prototype.sync(self: Ping, interactionData: apiTypes.InteractionObject)
	for _, behaviour in Ping.Behaviours do
		behaviour.inheritMethods(self)
		behaviour.inheritProperties(self, interactionData)
	end
end

--[=[
	@within Classes.Ping
	@private

	Responsible for constructing this class.
]=]
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
