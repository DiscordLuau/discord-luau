--[[
	Implementation of the Discord User class in Luau

	https://discord.com/developers/docs/resources/user#user-object
]]

local apiTypes = require("@api-types/apiTypes")

local avatarDecoration = require("@classes/avatarDecoration")

local User = {}

User.Interface = {}
User.Prototype = {}

function User.Prototype.sync(self: User, userData: apiTypes.UserObject)
	local premiumType: NitroType = "None"

	if userData.premium_type == 1 then
		premiumType = "NitroClassic"
	elseif userData.premium_type == 2 then
		premiumType = "Nitro"
	elseif userData.premium_type == 3 then
		premiumType = "NitroBasic"
	end

	self.premiumType = premiumType

	self.username = userData.username
	self.discriminator = userData.discriminator
	self.globalName = userData.global_name
	self.avatar = userData.avatar
	self.bot = userData.bot
	self.system = userData.system
	self.mfaEnabled = userData.mfa_enabled
	self.banner = userData.banner
	self.accentColor = userData.accent_color
	self.locale = userData.locale
	self.verified = userData.verified
	self.email = userData.email
	self.flags = userData.flags
	self.publicFlags = userData.public_flags
	self.avatarDecorationData = userData.avatar_decoration_data
		and avatarDecoration.new(userData.avatar_decoration_data.asset, userData.avatar_decoration_data.sku_id)
end

function User.Interface.new(userData: apiTypes.UserObject): User
	local self = setmetatable(
		{
			id = userData.id,
		} :: User,
		{ __index = User.Prototype }
	)

	if userData then
		self:sync(userData)
	end

	return self
end

export type NitroType = "None" | "NitroClassic" | "Nitro" | "NitroBasic"
export type User = typeof(User.Prototype) & {
	id: apiTypes.Snowflake,

	username: string,
	discriminator: string,
	globalName: string,
	avatar: string,
	bot: boolean?,
	system: boolean?,
	mfaEnabled: boolean?,
	banner: string?,
	accentColor: number?,
	locale: apiTypes.LanguageLocales?,
	verified: boolean?,
	email: string?,
	flags: number?,
	premiumType: NitroType?,
	publicFlags: number?,
	avatarDecorationData: avatarDecoration.AvatarDecoration?,
}

return User.Interface
