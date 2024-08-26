--[[
	Implementation of the Discord Data class in Luau

	https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-data
]]

local apiTypes = require("@api-types/apiTypes")
local interactionTypes = require("@api-types/interaction")

local resolved = require("@classes/resolved")
local state = require("@classes/state")

local dataOption = require("@classes/interaction/dataOption")

local Data = {}

Data.Interface = {}
Data.Prototype = {}

function Data.Prototype.sync(self: Data, dataObject: apiTypes.InteractionDataObject)
	local optionArray = {}

	for _, option in next, dataObject.options or {} do
		table.insert(optionArray, dataOption.new(option))
	end

	self.type = (
		dataObject.type == 1 and "SubCommand"
		or dataObject.type == 2 and "SubCommandGroup"
		or dataObject.type == 3 and "String"
		or dataObject.type == 4 and "Integer"
		or dataObject.type == 5 and "Boolean"
		or dataObject.type == 6 and "User"
		or dataObject.type == 7 and "Channel"
		or dataObject.type == 8 and "Role"
		or dataObject.type == 9 and "Mentionable"
		or dataObject.type == 10 and "Number"
		or dataObject.type == 11 and "Attachment"
	) :: interactionTypes.InteractionType

	self.id = dataObject.id
	self.name = dataObject.name
	self.options = optionArray
	self.resolved = dataObject.resolved and resolved.new(self.state, dataObject.resolved)
	self.guildId = dataObject.guild_id
	self.targetId = dataObject.target_id
end

function Data.Interface.new(state: state.State, dataObject: apiTypes.InteractionDataObject): Data
	local self = setmetatable(
		{
			state = state,
		} :: Data,
		{ __index = Data.Prototype }
	)

	self:sync(dataObject)

	return self
end

-- ensure any cyclic dependencies are also updated!
export type Data = typeof(Data.Prototype) & {
	state: state.State,

	id: apiTypes.Snowflake,
	name: string,
	type: interactionTypes.InteractionType,
	resolved: resolved.Resolved?,
	options: { dataOption.DataOption<unknown> },
	guildId: apiTypes.Snowflake?,
	targetId: apiTypes.Snowflake?,
}

return Data.Interface
