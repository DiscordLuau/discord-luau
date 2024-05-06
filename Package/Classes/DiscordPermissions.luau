local Construct = require("../Utils/Construct")
local Enumerate = require("../Utils/Enumerate")

--[=[
	@class DiscordPermissions

	(sorry I will add docs for this lol, just haven't got around to it yet!)
]=]
local DiscordPermissions = {}

DiscordPermissions.Interface = {}
DiscordPermissions.Prototype = {}

DiscordPermissions.Prototype.type = "DiscordPermissions"

--[=[
	@prop Permissions { ... }
	@within DiscordPermissions
]=]
DiscordPermissions.Interface.Permissions = Enumerate.new({
	CreateInstantInvite = 0,
	KickMembers = 1,
	BanMembers = 2,
	Administrator = 3,
	ManageChannels = 4,
	ManageGuild = 5,
	AddReactions = 6,
	ViewAuditLog = 7,
	PrioritySpeaker = 8,
	Stream = 9,
	ViewChannel = 10,
	SendMessages = 11,
	SendTTSMessages = 12,
	ManageMesseges = 13,
	EmbedLinks = 14,
	AttachFiles = 15,
	ReadMessageHistory = 16,
	MentionEveryone = 17,
	UseExternalEmojis = 18,
	ViewGuildInsights = 19,
	Connect = 20,
	Speak = 21,
	MuteMembers = 22,
	DeafenMembers = 23,
	MoveMembers = 24,
	UseVAD = 25,
	ChangeNickname = 26,
	ChangeNicknames = 27,
	ManageRoles = 28,
	ManageWebhooks = 29,
	ManageGuildExpressions = 30,
	UseApplicationCommands = 31,
	RequestToSpeak = 32,
	ManageEvents = 33,
	ManageThreads = 34,
	CreatePublicThreads = 35,
	CreatePrivateThreads = 36,
	UseExternalStickers = 37,
	SendMessagesInThreads = 38,
	UseEmbeddedActivities = 39,
	ModerateMembers = 40,
	ViewCreatorMonetizationAnalytics = 41,
	UseSoundboard = 42,
	UseExternalSounds = 45,
	SendVoiceMessages = 46
})

--[=[
	@method addPermission
	@within DiscordPermissions

	@permission permission DiscordPermissions.Permission

	@return DiscordPermissions

	...

	```lua
		
	```
]=]
function DiscordPermissions.Prototype.addPermission(self: DiscordPermissions, permission: number)
	if table.find(self.permissions, permission) then
		return
	end

	table.insert(self.permissions, permission)

	return self
end

--[=[
	@method deletePermission
	@within DiscordPermissions

	@permission permission DiscordPermissions.Permission

	@return DiscordPermissions

	...

	```lua
		
	```
]=]
function DiscordPermissions.Prototype.deletePermission(self: DiscordPermissions, permission: number)
	local index = table.find(self.permissions, permission)

	if not index then
		return self
	end

	table.remove(self.permissions, index)

	return self
end

--[=[
	@method hasPermission
	@within DiscordPermissions

	@permission permission DiscordPermissions.Permission

	@return boolean

	...

	```lua
		
	```
]=]
function DiscordPermissions.Prototype.hasPermission(self: DiscordPermissions, permission: number)
	return table.find(self.permissions, permission) ~= nil
end

--[=[
	@method getValue
	@within DiscordPermissions

	@return number

	...

	```lua
		
	```
]=]
function DiscordPermissions.Prototype.getValue(self: DiscordPermissions)
	local permissionsInt = 0

	for _, intentValue in (self.permissions :: { }) do
		permissionsInt += bit32.lshift(1, intentValue)
	end

	return tostring(permissionsInt)
end

--[=[
	@function new
	@within DiscordPermissions

	@return DiscordPermissions

	...

	```lua
		
	```
]=]
function DiscordPermissions.Interface.new()
	return Construct({
		permissions = {}
	}, DiscordPermissions.Prototype)
end

--[=[
	@function none
	@within DiscordPermissions

	@return DiscordPermissions

	...

	```lua
		
	```
]=]
function DiscordPermissions.Interface.none()
	return DiscordPermissions.Interface.new()
end

--[=[
	@function all
	@within DiscordPermissions

	@return DiscordPermissions

	...

	```lua
		
	```
]=]
function DiscordPermissions.Interface.all()
	local permissions = DiscordPermissions.Interface.new()

	for _, value in DiscordPermissions.Interface.Permissions do
		permissions:addPermission(value)
	end

	return permissions
end

--[=[
	@function from
	@within DiscordPermissions

	@param bitfield number

	@return DiscordPermissions

	...

	```lua
		
	```
]=]
function DiscordPermissions.Interface.from(bitfield: string)
	local permissions = DiscordPermissions.Interface.new()
	local numberBitfield = tonumber(bitfield)

	for _, value in DiscordPermissions.Interface.Permissions do
		if bit32.band(numberBitfield, value) == value then
			permissions:addPermission(value)
		end
	end

	return permissions
end

export type DiscordPermissions = typeof(DiscordPermissions.Prototype) & {
	permissions: { number }
}

return DiscordPermissions.Interface