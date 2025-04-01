--[=[
	@class Classes.MessageInteraction
	@__index Prototype

	Implementation of the Discord Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#message-interaction-object-message-interaction-structure
]=]

local apiTypes = require("../../lune_packages/api_types")
local state = require("../../lune_packages/state")

local user = require("../user")
local member = require("../guild/member")

local Interaction = {}

Interaction.Interface = {}
Interaction.Prototype = {}

--[=[
	@within Classes.MessageInteraction
	@private

	Responsible for syncing data to this interaction object. This is typically called by the API when this object is
	created or updated.
]=]
function Interaction.Prototype.sync(self: Interaction, interactionData: apiTypes.MessageInteractionObject)
	--[=[
		@prop type apiTypes.InteractionType
		@within Classes.MessageInteraction
		The type of interaction that was performed
	]=]
	self.type = apiTypes.interaction.InteractionType[interactionData.type]

	--[=[
		@prop user Classes.User
		@within Classes.MessageInteraction
		The user who triggered the interaction
	]=]
	self.user = user.new(interactionData.user)

	--[=[
		@prop member Classes.Member?
		@within Classes.MessageInteraction
		The member who triggered the interaction, if in a guild
	]=]
	self.member = interactionData.member and member.new(self.state, "interaction", interactionData.member)

	--[=[
		@prop id string
		@within Classes.MessageInteraction
		The ID of the interaction
	]=]
	self.id = interactionData.id

	--[=[
		@prop name string
		@within Classes.MessageInteraction
		The name of the application command
	]=]
	self.name = interactionData.name
end

--[=[
	@within Classes.MessageInteraction
	@private

	Responsible for constructing this class.
]=]
function Interaction.Interface.new(state: state.State, interactionData: apiTypes.MessageInteractionObject): Interaction
	local self = setmetatable(
		{
			--[=[
				@prop state state.State
				@within Classes.MessageInteraction
				The state object that this interaction is associated with
			]=]
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
