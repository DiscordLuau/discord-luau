--[=[
	@class Commands.Guards

	Built-in guards for common access control patterns.
]=]

local classes = require("../luau_packages/classes")

local Guards = {}

--[=[
	@within Commands.Guards

	Returns true if the interaction was invoked inside a guild.
]=]
function Guards.guildOnly(interaction: classes.TypesCommand): boolean
	return interaction.guildId ~= nil
end

--[=[
	@within Commands.Guards

	Returns true if the interaction was invoked in a DM.
]=]
function Guards.dmOnly(interaction: classes.TypesCommand): boolean
	return not interaction.guildId
end

--[=[
	@within Commands.Guards

	Returns a guard that passes only if the invoking user's ID is in `ownerIds`.
]=]
function Guards.ownerOnly(ownerIds: { string }): (interaction: classes.TypesCommand) -> boolean
	return function(interaction: classes.TypesCommand): boolean
		local userId: string?

		if interaction.user then
			userId = interaction.user.id
		elseif interaction.member then
			local memberUser = interaction.member.user

			if memberUser then
				userId = memberUser.id
			end
		end

		if not userId then
			return false
		end

		return table.find(ownerIds, userId) ~= nil
	end
end

export type Guard = (interaction: classes.TypesCommand) -> boolean

return Guards
