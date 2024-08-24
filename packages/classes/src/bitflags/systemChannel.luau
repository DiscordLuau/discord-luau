--[[
	Implementation of the Discord Role Bitflags in Luau

	https://discord.com/developers/docs/resources/guild#guild-object-system-channel-flags
]]

local SystemChannelBitflag = {}

SystemChannelBitflag.Interface = {}
SystemChannelBitflag.Prototype = {}

--[[
	Returns if the system channel has the suppress join notifications bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressJoinNotifications(self: SystemChannelBitflag)
	return bit32.lshift(self.flag, 0) == 0
end

--[[
	Returns if the system channel has the suppress premium subscriptions bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressPremiumSubscriptions(self: SystemChannelBitflag)
	return bit32.lshift(self.flag, 0) == 1
end

--[[
	Returns if the system channel has the suppress guild reminder notifications bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressGuildReminderNotifications(self: SystemChannelBitflag)
	return bit32.lshift(self.flag, 0) == 2
end

--[[
	Returns if the system channel has the suppress join notification replies bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressJoinNotificationReplies(self: SystemChannelBitflag)
	return bit32.lshift(self.flag, 0) == 3
end

--[[
	Returns if the system channel has the suppress role subscriptions purchase notifications bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressRoleSubscriptionPurchaseNotifications(self: SystemChannelBitflag)
	return bit32.lshift(self.flag, 0) == 4
end

--[[
	Returns if the system channel has the suppress role subscriptions purchase notification replies bitflag set.
]]
function SystemChannelBitflag.Prototype.suppressRoleSubscriptionPurchaseNotificationReplies(self: SystemChannelBitflag)
	return bit32.lshift(self.flag, 0) == 5
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
