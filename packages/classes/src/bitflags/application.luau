--[=[
	@class Classes.ApplicationBitflag
	@__index Prototype

	Implementation of the Discord Application Bitflags in Luau.
	This class provides methods to check various application flags that indicate different states and capabilities of a Discord application.

	https://discord.com/developers/docs/resources/application#application-object-application-flags
]=]

local bit = require("../../luau_packages/bit")

local ApplicationBitflag = {}

ApplicationBitflag.Interface = {}
ApplicationBitflag.Prototype = {}

--[=[
	@within Classes.ApplicationBitflag
	Indicates if an app uses the Auto Moderation API
]=]
function ApplicationBitflag.Prototype.applicationAutoModerationRoleCreateBadge(self: ApplicationBitflag)
	local targetBit = bit.lshift(1, 6)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.ApplicationBitflag
	Intent required for bots in 100 or more servers to receive presence_update events
]=]
function ApplicationBitflag.Prototype.gatewayPresence(self: ApplicationBitflag)
	local targetBit = bit.lshift(1, 12)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.ApplicationBitflag
	Intent required for bots in under 100 servers to receive presence_update events,
	found on the Bot page in your app's settings
]=]
function ApplicationBitflag.Prototype.gatewayPresenceLimited(self: ApplicationBitflag)
	local targetBit = bit.lshift(1, 13)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.ApplicationBitflag
	Intent required for bots in 100 or more servers to receive member-related events like
	guild_member_add. See the list of member-related events under GUILD_MEMBERS
]=]
function ApplicationBitflag.Prototype.gatewayGuildMembers(self: ApplicationBitflag)
	local targetBit = bit.lshift(1, 14)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.ApplicationBitflag
	Intent required for bots in under 100 servers to receive member-related events
	like guild_member_add, found on the Bot page in your app's settings.

	See the list of member-related events under GUILD_MEMBERS
]=]
function ApplicationBitflag.Prototype.gatewayGuildMembersLimited(self: ApplicationBitflag)
	local targetBit = bit.lshift(1, 15)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.ApplicationBitflag
	Indicates unusual growth of an app that prevents verification
]=]
function ApplicationBitflag.Prototype.verificationPendingGuildLimit(self: ApplicationBitflag)
	local targetBit = bit.lshift(1, 16)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.ApplicationBitflag
	Indicates if an app is embedded within the Discord client (currently unavailable publicly)
]=]
function ApplicationBitflag.Prototype.embedded(self: ApplicationBitflag)
	local targetBit = bit.lshift(1, 17)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.ApplicationBitflag
	Intent required for bots in 100 or more servers to receive message content
]=]
function ApplicationBitflag.Prototype.gatewayMessageContent(self: ApplicationBitflag)
	local targetBit = bit.lshift(1, 18)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.ApplicationBitflag
	Intent required for bots in under 100 servers to receive message content,
	found on the Bot page in your app's settings
]=]
function ApplicationBitflag.Prototype.gatewayMessageContentLimited(self: ApplicationBitflag)
	local targetBit = bit.lshift(1, 19)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.ApplicationBitflag
	Indicates if an app has registered global application commands
]=]
function ApplicationBitflag.Prototype.applicationCommandBadge(self: ApplicationBitflag)
	local targetBit = bit.lshift(1, 23)

	return bit.band(self.flag, targetBit) == targetBit
end

--[=[
	@within Classes.ApplicationBitflag
	@private

	Creates a new ApplicationBitflag instance with the specified flag value.
]=]
function ApplicationBitflag.Interface.new(flag: number): ApplicationBitflag
	local self = setmetatable(
		{
			flag = flag,
		} :: ApplicationBitflag,
		{ __index = ApplicationBitflag.Prototype }
	)

	return self
end

export type ApplicationBitflag = typeof(ApplicationBitflag.Prototype) & {
	flag: number,
}

return ApplicationBitflag.Interface
