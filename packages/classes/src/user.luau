--[=[
	@class Classes.User
	@__index Prototype

	Implementation of the Discord User class in Luau

	https://discord.com/developers/docs/resources/user#user-object
]=]

local apiTypes = require("../lune_packages/api_types")

local avatarDecoration = require("./avatarDecoration")

local User = {}

User.Interface = {}
User.Prototype = {}

--[=[
	@within Classes.User
	@private

	Responsible for syncing data to this webhook object. This is typically called by the API when this object is
	created or updated.
]=]
function User.Prototype.sync(self: User, userData: apiTypes.UserObject)
	--[=[
		@prop id string
		@within Classes.User
		The unique identifier for this user.
	]=]
	self.id = userData.id

	--[=[
		@prop username string
		@within Classes.User
		The username of this user.
	]=]
	self.username = userData.username

	--[=[
		@prop discriminator string?
		@within Classes.User
		The discriminator of this user, used to distinguish between users with the same username.
	]=]
	self.discriminator = userData.discriminator

	--[=[
		@prop globalName string?
		@within Classes.User
		The global display name of this user, if they have one set.
	]=]
	self.globalName = userData.global_name

	--[=[
		@prop avatar string?
		@within Classes.User
		The avatar hash of this user.
	]=]
	self.avatar = userData.avatar

	--[=[
		@prop avatarDecoration Classes.AvatarDecoration?
		@within Classes.User
		The avatar decoration of this user, if they have one.
	]=]
	self.avatarDecorationData = userData.avatar_decoration_data
		and avatarDecoration.new(userData.avatar_decoration_data.asset, userData.avatar_decoration_data.sku_id)

	--[=[
		@prop bot boolean?
		@within Classes.User
		Whether this user is a bot account.
	]=]
	self.bot = userData.bot

	--[=[
		@prop system boolean?
		@within Classes.User
		Whether this user is a system account.
	]=]
	self.system = userData.system

	--[=[
		@prop mfaEnabled boolean?
		@within Classes.User
		Whether this user has two-factor authentication enabled.
	]=]
	self.mfaEnabled = userData.mfa_enabled

	--[=[
		@prop locale string?
		@within Classes.User
		The user's preferred language.
	]=]
	self.locale = userData.locale

	--[=[
		@prop verified boolean?
		@within Classes.User
		Whether this user's email is verified.
	]=]
	self.verified = userData.verified

	--[=[
		@prop banner string?
		@within Classes.User
	]=]
	self.banner = userData.banner

	--[=[
		@prop email string?
		@within Classes.User
		The user's email address.
	]=]
	self.email = userData.email

	--[=[
		@prop flags Classes.UserBitflag?
		@within Classes.User
		The flags that indicate various properties and states of the user.
	]=]
	self.flags = userData.flags

	--[=[
		@prop premiumType apiTypes.PremiumType?
		@within Classes.User
		The type of Nitro subscription this user has.
	]=]
	self.premiumType = userData.premium_type and apiTypes.user.PremiumType[userData.premium_type]

	--[=[
		@prop publicFlags Classes.UserBitflag?
		@within Classes.User
		The public flags that indicate various properties and states of the user.
	]=]
	self.publicFlags = userData.public_flags

	--[=[
		@prop accentColor number?
		@within Classes.User
		The user's custom profile accent color.
	]=]
	self.accentColor = userData.accent_color
end

--[=[
	@within Classes.User
	@private

	Responsible for constructing this class.
]=]
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
	premiumType: apiTypes.NitroType?,
	publicFlags: number?,
	avatarDecorationData: avatarDecoration.AvatarDecoration?,
}

return User.Interface
