local DiscordPermissions = {}

DiscordPermissions.Type = "DiscordPermissions"

DiscordPermissions.Internal = {}
DiscordPermissions.Interface = {}
DiscordPermissions.Prototype = {
	Internal = DiscordPermissions.Internal,
}

DiscordPermissions.Interface.Permissions = {
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
}

function DiscordPermissions.Prototype:AddPermission(permission)
	if table.find(self.Permissions, permission) then
		return
	end

	table.insert(self.Permissions, permission)
end

function DiscordPermissions.Prototype:DeletePermission(permission)
	local index = table.find(self.Permissions, permission)

	if not index then
		return
	end

	table.remove(self.Permissions, index)
end

function DiscordPermissions.Prototype:GetValue()
	local permissionsInt = 0

	for _, intentValue in self.Permissions do
		permissionsInt += bit32.lshift(1, intentValue)
	end

	return permissionsInt
end

function DiscordPermissions.Prototype:ToString()
	return `{DiscordPermissions.Type}<{self.Name or "Unknown Activity"}>`
end

function DiscordPermissions.Interface.new()
	return setmetatable({
		Permissions = {}
	}, {
		__index = DiscordPermissions.Prototype,
		__type = DiscordPermissions.Type,
		__tostring = function(self)
			return self:ToString()
		end,
	})
end

function DiscordPermissions.Interface.none()
	return DiscordPermissions.Interface.new()
end

function DiscordPermissions.Interface.all()
	local permissions = DiscordPermissions.Interface.new()

	for _, value in DiscordPermissions.Interface.Permissions do
		permissions:AddPermission(value)
	end

	return permissions
end

return DiscordPermissions.Interface
