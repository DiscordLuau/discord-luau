--[=[
	@class Classes.Message.Interaction
	@__index Prototype

	Implementation of the Discord Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#message-interaction-object-message-interaction-structure
]=]

--[=[
	@prop type apiTypes.InteractionType
	@within Classes.Message.Interaction
	The type of interaction that was performed
]=]

--[=[
	@prop user Classes.User
	@within Classes.Message.Interaction
	The user who triggered the interaction
]=]

--[=[
	@prop member Classes.Guild.Member?
	@within Classes.Message.Interaction
	The member who triggered the interaction, if in a guild
]=]

--[=[
	@prop id string
	@within Classes.Message.Interaction
	The ID of the interaction
]=]

--[=[
	@prop name string
	@within Classes.Message.Interaction
	The name of the application command
]=]

--[=[
	@prop state state.State
	@within Classes.Message.Interaction
	The state object that this interaction is associated with
]=]

local apiTypes = require("../../luau_packages/api_types")
local state = require("../../luau_packages/state")

local user = require("../user")
local member = require("../guild/member")

local Interaction = {}

Interaction.Interface = {}
Interaction.Prototype = {}

--[=[
	@within Classes.Message.Interaction
	@private

	Responsible for syncing data to this interaction object. This is typically called by the API when this object is
	created or updated.
]=]
function Interaction.Prototype.sync(self: Interaction, interactionData: apiTypes.MessageInteractionObject)
	self.type = apiTypes.interaction.InteractionType[interactionData.type]

	self.user = user.new(interactionData.user)

	self.member = interactionData.member and member.new(self.state, "interaction", interactionData.member)

	self.id = interactionData.id

	self.name = interactionData.name
end

--[=[
	@within Classes.Message.Interaction
	@private

	Responsible for constructing this class.
]=]
function Interaction.Interface.new(state: state.State, interactionData: apiTypes.MessageInteractionObject): Interaction
	local self = setmetatable(
		{
			state = state,
		} :: Interaction,
		{ __index = Interaction.Prototype }
	)

	self:sync(interactionData)

	return self
end

export type Interaction = typeof(Interaction.Prototype) & {
	state: state.State,

	id: apiTypes.Snowflake,
	type: apiTypes.InteractionType,
	name: string,
	user: user.User,
	member: member.Member?,
}

return Interaction.Interface
