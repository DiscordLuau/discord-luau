--[[
	Implementation of the Discord Role Bitflags in Luau

	https://discord.com/developers/docs/resources/guild#guild-object-system-channel-flags
]]

local bit = require("../../luau_packages/bit")

local SystemChannelBitflag = {}

SystemChannelBitflag.Interface = {}
SystemChannelBitflag.Prototype = {}

--[[
	Returns if the system channel has the suppress join notifications bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressJoinNotifications(self: SystemChannelBitflag)
	local targetBit = bit.lshift(1, 0)

	return bit.band(self.flag, targetBit) == targetBit
end

--[[
	Returns if the system channel has the suppress premium subscriptions bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressPremiumSubscriptions(self: SystemChannelBitflag)
	local targetBit = bit.lshift(1, 1)

	return bit.band(self.flag, targetBit) == targetBit
end

--[[
	Returns if the system channel has the suppress guild reminder notifications bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressGuildReminderNotifications(self: SystemChannelBitflag)
	local targetBit = bit.lshift(1, 2)

	return bit.band(self.flag, targetBit) == targetBit
end

--[[
	Returns if the system channel has the suppress join notification replies bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressJoinNotificationReplies(self: SystemChannelBitflag)
	local targetBit = bit.lshift(1, 3)

	return bit.band(self.flag, targetBit) == targetBit
end

--[[
	Returns if the system channel has the suppress role subscriptions purchase notifications bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressRoleSubscriptionPurchaseNotifications(self: SystemChannelBitflag)
	local targetBit = bit.lshift(1, 4)

	return bit.band(self.flag, targetBit) == targetBit
end

--[[
	Returns if the system channel has the suppress role subscriptions purchase notification replies bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressRoleSubscriptionPurchaseNotificationReplies(self: SystemChannelBitflag)
	local targetBit = bit.lshift(1, 5)

	return bit.band(self.flag, targetBit) == targetBit
end

function SystemChannelBitflag.Interface.new(flag: number): SystemChannelBitflag
	local self = setmetatable(
		{
			flag = flag,
		} :: SystemChannelBitflag,
		{ __index = SystemChannelBitflag.Prototype }
	)

	return self
end

export type SystemChannelBitflag = typeof(SystemChannelBitflag.Prototype) & {
	flag: number,
}

return SystemChannelBitflag.Interface
