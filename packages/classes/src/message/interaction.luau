--[[
	Implementation of the Discord Interaction class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#message-interaction-object-message-interaction-structure
]]

local apiTypes = require("@api-types/apiTypes")
local messageTypes = require("@api-types/message")

local user = require("@classes/user")
local guildMember = require("@classes/guildMember")

local Interaction = {}

Interaction.Interface = {}
Interaction.Prototype = {}

function Interaction.Prototype.sync(self: Interaction, interactionData: apiTypes.MessageInteractionObject)
	self.type = (
		interactionData.type == 1 and "Ping"
		or interactionData.type == 2 and "ApplicationCommand"
		or interactionData.type == 3 and "MessageComponent"
		or interactionData.type == 4 and "ApplicationCommandAutocomplete"
		or interactionData.type == 5 and "ModalSubmit"
	) :: messageTypes.InteractionType

	self.user = user.new(interactionData.user)
	self.member = interactionData.member and guildMember.new(interactionData.member)

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
	type: messageTypes.InteractionType,
	name: string,
	user: user.User,
	member: guildMember.GuildMember?,
}

return Interaction.Interface
