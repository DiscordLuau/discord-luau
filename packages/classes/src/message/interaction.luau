--[[
	Implementation of the Discord Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#message-interaction-object-message-interaction-structure
]]

local apiTypes = require("@api-types/apiTypes")
local interactionTypes = require("@api-types/interaction")

local user = require("@classes/user")
local member = require("@classes/guild/member")

local Interaction = {}

Interaction.Interface = {}
Interaction.Prototype = {}

function Interaction.Prototype.sync(self: Interaction, interactionData: apiTypes.MessageInteractionObject)
	self.type = interactionTypes.InteractionType[interactionData.type]

	self.user = user.new(interactionData.user)
	self.member = interactionData.member and member.new(interactionData.member)

	self.id = interactionData.id
	self.name = interactionData.name
end

function Interaction.Interface.new(interactionData: apiTypes.MessageInteractionObject): Interaction
	local self = setmetatable({} :: Interaction, { __index = Interaction.Prototype })

	self:sync(interactionData)

	return self
end

export type Interaction = typeof(Interaction.Prototype) & {
	id: apiTypes.Snowflake,
	type: interactionTypes.InteractionType,
	name: string,
	user: user.User,
	member: member.Member?,
}

return Interaction.Interface
