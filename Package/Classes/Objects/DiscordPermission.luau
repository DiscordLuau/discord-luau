local Construct = require("@Utils/Construct")

local PermissionsBuilder = require("@Builders/PermissionsBuilder")

--[=[
	@class Builders.DiscordPermission

	Represents a set of Discord permissions.
]=]

--[=[
	@prop permissions { number }
	@within Builders.DiscordPermission
]=]

local DiscordPermission = {}

DiscordPermission.Interface = {}
DiscordPermission.Prototype = {}

DiscordPermission.Prototype.type = "DiscordPermission"

function DiscordPermission.Prototype.hasPermission(self: DiscordPermission, permission: number)
	return table.find(self.permissions, permission) ~= nil
end

function DiscordPermission.Interface.from(bitfield: string)
	local permissions = Construct({ permissions = {} }, DiscordPermission.Prototype)
	local numberBitfield = tonumber(bitfield)

	assert(numberBitfield, `Invalid BitField '{bitfield}'`)

	for _, value in PermissionsBuilder.Permissions :: { number } do
		if bit32.band(numberBitfield, value) == value then
			table.insert(permissions.permissions, value)
		end
	end

	return permissions
end

export type DiscordPermission = typeof(DiscordPermission.Prototype) & {
	permissions: { number },
}

return DiscordPermission.Interface
