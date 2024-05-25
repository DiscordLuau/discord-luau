local Construct = require("../../Utils/Construct")
local Enumerate = require("../../Utils/Enumerate")

--[=[
	@class Builders.PermissionsBuilder

	PermissionsBuilder is used to construct and manage permissions for a Discord bot.

	Usage:
	```lua
	local permissions = PermissionsBuilder.new()
		:addPermission(PermissionsBuilder.Permissions.Administrator)
		:addPermission(PermissionsBuilder.Permissions.ManageChannels)

	print(permissions:getValue())
	```
]=]
local PermissionsBuilder = {}

PermissionsBuilder.Interface = {}
PermissionsBuilder.Prototype = {}

PermissionsBuilder.Prototype.type = "PermissionsBuilder"

--[=[
	@prop Permissions table
	@within Builders.PermissionsBuilder

	An enumeration of permissions.

	- CreateInstantInvite: 0
	- KickMembers: 1
	- BanMembers: 2
	- Administrator: 3
	- ManageChannels: 4
	- ManageGuild: 5
	- AddReactions: 6
	- ViewAuditLog: 7
	- PrioritySpeaker: 8
	- Stream: 9
	- ViewChannel: 10
	- SendMessages: 11
	- SendTTSMessages: 12
	- ManageMessages: 13
	- EmbedLinks: 14
	- AttachFiles: 15
	- ReadMessageHistory: 16
	- MentionEveryone: 17
	- UseExternalEmojis: 18
	- ViewGuildInsights: 19
	- Connect: 20
	- Speak: 21
	- MuteMembers: 22
	- DeafenMembers: 23
	- MoveMembers: 24
	- UseVAD: 25
	- ChangeNickname: 26
	- ChangeNicknames: 27
	- ManageRoles: 28
	- ManageWebhooks: 29
	- ManageGuildExpressions: 30
	- UseApplicationCommands: 31
	- RequestToSpeak: 32
	- ManageEvents: 33
	- ManageThreads: 34
	- CreatePublicThreads: 35
	- CreatePrivateThreads: 36
	- UseExternalStickers: 37
	- SendMessagesInThreads: 38
	- UseEmbeddedActivities: 39
	- ModerateMembers: 40
	- ViewCreatorMonetizationAnalytics: 41
	- UseSoundboard: 42
	- UseExternalSounds: 45
	- SendVoiceMessages: 46
]=]
PermissionsBuilder.Interface.Permissions = Enumerate.new({
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
	ManageMessages = 13,
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
	SendVoiceMessages = 46,
})

--[=[
	Adds a permission to the builder.
	
	@method addPermission
	@param permission number -- The permission to add.
	@within Builders.PermissionsBuilder
	@return Builders.PermissionsBuilder -- Returns the PermissionsBuilder instance for method chaining.
]=]
function PermissionsBuilder.Prototype.addPermission(self: PermissionsBuilder, permission: number)
	if table.find(self.permissions, permission) then
		return
	end

	table.insert(self.permissions, permission)

	return self
end

--[=[
	Removes a permission from the builder.
	
	@method deletePermission
	@param permission number -- The permission to remove.
	@within Builders.PermissionsBuilder
	@return Builders.PermissionsBuilder -- Returns the PermissionsBuilder instance for method chaining.
]=]
function PermissionsBuilder.Prototype.deletePermission(self: PermissionsBuilder, permission: number)
	local index = table.find(self.permissions, permission)

	if not index then
		return self
	end

	table.remove(self.permissions, index)

	return self
end

--[=[
	Checks if a permission is in the builder.
	
	@method hasPermission
	@param permission number -- The permission to check.
	@within Builders.PermissionsBuilder
	@return boolean -- Returns true if the permission is in the builder, false otherwise.
]=]
function PermissionsBuilder.Prototype.hasPermission(self: PermissionsBuilder, permission: number)
	return table.find(self.permissions, permission) ~= nil
end

--[=[
	Gets the bitfield value of the permissions.
	
	@method getValue
	@within Builders.PermissionsBuilder
	@return string -- The bitfield value as a string.
]=]
function PermissionsBuilder.Prototype.getValue(self: PermissionsBuilder)
	local permissionsInt = 0

	for _, intentValue in self.permissions do
		permissionsInt += bit32.lshift(1, intentValue)
	end

	return tostring(permissionsInt)
end

--[=[
	Creates a new instance of PermissionsBuilder.
	
	@function new
	@within Builders.PermissionsBuilder
	@return Builders.PermissionsBuilder -- A new instance of PermissionsBuilder.
]=]
function PermissionsBuilder.Interface.new()
	return Construct({
		permissions = {},
	}, PermissionsBuilder.Prototype)
end

--[=[
	Creates a new instance of PermissionsBuilder with no permissions.
	
	@function none
	@within Builders.PermissionsBuilder
	@return Builders.PermissionsBuilder -- A new instance of PermissionsBuilder.
]=]
function PermissionsBuilder.Interface.none()
	return PermissionsBuilder.Interface.new()
end

--[=[
	Creates a new instance of PermissionsBuilder with all permissions.
	
	@function all
	@within Builders.PermissionsBuilder
	@return Builders.PermissionsBuilder -- A new instance of PermissionsBuilder.
]=]
function PermissionsBuilder.Interface.all()
	local permissions = PermissionsBuilder.Interface.new()

	for _, value in PermissionsBuilder.Interface.Permissions :: {} do
		permissions:addPermission(value :: number)
	end

	return permissions
end

--[=[
	Creates a new instance of PermissionsBuilder from a bitfield.
	
	@function from
	@param bitfield string -- The bitfield representing the permissions.
	@within Builders.PermissionsBuilder
	@return Builders.PermissionsBuilder -- A new instance of PermissionsBuilder.
]=]
function PermissionsBuilder.Interface.from(bitfield: string)
	local permissions = PermissionsBuilder.Interface.new()
	local numberBitfield = tonumber(bitfield)

	assert(numberBitfield, `Invalid BitField '{bitfield}'`)

	for _, value in PermissionsBuilder.Interface.Permissions :: {} do
		if bit32.band(numberBitfield, value :: number) == value then
			permissions:addPermission(value :: number)
		end
	end

	return permissions
end

export type PermissionsBuilder = typeof(PermissionsBuilder.Prototype) & {
	permissions: { number },
}

return PermissionsBuilder.Interface
