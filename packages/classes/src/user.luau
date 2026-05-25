--[=[
	@class Classes.User
	@__index Prototype

	Implementation of the Discord User class in Luau

	https://discord.com/developers/docs/resources/user#user-object
]=]

--[=[
	@prop id string
	@within Classes.User
	The unique identifier for this user.
]=]

--[=[
	@prop username string
	@within Classes.User
	The username of this user.
]=]

--[=[
	@prop discriminator string?
	@within Classes.User
	The discriminator of this user, used to distinguish between users with the same username.
]=]

--[=[
	@prop globalName string?
	@within Classes.User
	The global display name of this user, if they have one set.
]=]

--[=[
	@prop avatar string?
	@within Classes.User
	The avatar hash of this user.
]=]

--[=[
	@prop avatarDecoration Classes.AvatarDecoration?
	@within Classes.User
	The avatar decoration of this user, if they have one.
]=]

--[=[
	@prop bot boolean?
	@within Classes.User
	Whether this user is a bot account.
]=]

--[=[
	@prop system boolean?
	@within Classes.User
	Whether this user is a system account.
]=]

--[=[
	@prop mfaEnabled boolean?
	@within Classes.User
	Whether this user has two-factor authentication enabled.
]=]

--[=[
	@prop locale string?
	@within Classes.User
	The user's preferred language.
]=]

--[=[
	@prop verified boolean?
	@within Classes.User
	Whether this user's email is verified.
]=]

--[=[
	@prop banner string?
	@within Classes.User
]=]

--[=[
	@prop email string?
	@within Classes.User
	The user's email address.
]=]

--[=[
	@prop flags Classes.UserBitflag?
	@within Classes.User
	The flags that indicate various properties and states of the user.
]=]

--[=[
	@prop premiumType apiTypes.PremiumType?
	@within Classes.User
	The type of Nitro subscription this user has.
]=]

--[=[
	@prop publicFlags Classes.UserBitflag?
	@within Classes.User
	The public flags that indicate various properties and states of the user.
]=]

--[=[
	@prop accentColor number?
	@within Classes.User
	The user's custom profile accent color.
]=]

local apiTypes = require("../luau_packages/api_types")
local state = require("../luau_packages/state")
local future = require("../luau_packages/future")
local rest = require("../luau_packages/rest")

local avatarDecoration = require("./avatarDecoration")
local primaryGuild = require("./primaryGuild")

local User = {}

User.Interface = {}
User.Prototype = {}

--[=[
	@within Classes.User

	Responsible for syncing data to this webhook object. This is typically called by the API when this object is
	created or updated.
]=]
function User.Prototype.sync(self: User, userData: apiTypes.UserObject)
	self.id = userData.id

	self.username = userData.username

	self.discriminator = userData.discriminator

	self.globalName = userData.global_name

	self.avatar = userData.avatar

	self.avatarDecorationData = userData.avatar_decoration_data
		and avatarDecoration.new(userData.avatar_decoration_data.asset, userData.avatar_decoration_data.sku_id)

	self.primaryGuild = userData.primary_guild and primaryGuild.new(userData.primary_guild)

	self.bot = userData.bot

	self.system = userData.system

	self.mfaEnabled = userData.mfa_enabled

	self.locale = userData.locale

	self.verified = userData.verified

	self.banner = userData.banner

	self.email = userData.email

	self.flags = userData.flags

	self.premiumType = userData.premium_type and apiTypes.user.PremiumType[userData.premium_type]

	self.publicFlags = userData.public_flags

	self.accentColor = userData.accent_color
end

--[=[
	@within Classes.User

	Modifies the bot's own username or avatar. Requires state; only valid when this User object
	represents the current bot user.
]=]
function User.Prototype.modifyAsync(self: User, username: string?, avatarData: string?): future.FutureLike<string, User>
	assert(self.state, "Cannot modify user: this User object has no state reference")
	return future.Future.new(function()
		local request = self.state.rest:newRequest()
		local response =
			rest.user.modifyCurrentUserAsync(request, { username = username, avatar = avatarData } :: any):await()
		assert(response:isOk(), `{response:unwrapErr()}`)
		self:sync(response:unwrapOk())
		return self
	end) :: future.FutureLike<string, User>
end

--[=[
	@within Classes.User

	Opens a DM channel with this user.
]=]
function User.Prototype.getDmChannelIdAsync(self: User): future.FutureLike<string, apiTypes.Snowflake>
	assert(self.state, "Cannot open DM channel: this User object has no state reference")
	return future.Future.new(function()
		local request = self.state.rest:newRequest()
		local response = rest.user.createDMAsync(request, { recipient_id = self.id }):await()
		assert(response:isOk(), `{response:unwrapErr()}`)
		return response:unwrapOk().id
	end) :: future.FutureLike<string, apiTypes.Snowflake>
end

--[=[
	@within Classes.User

	Responsible for constructing this class.
]=]
function User.Interface.new(userData: apiTypes.UserObject, userState: state.State?): User
	local self = setmetatable(
		{
			id = userData.id,
		} :: User,
		{ __index = User.Prototype }
	)

	self.state = userState

	if userData then
		self:sync(userData)
	end

	return self
end

export type User = typeof(User.Prototype) & {
	id: apiTypes.Snowflake,

	state: state.State?,

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
	primaryGuild: primaryGuild.PrimaryGuild?,
}

return User.Interface
