--[=[
	@class Builders.Invite
	@__index Prototype

	Implementation of discords Invite object as a Luau builder.	

	https://discord.com/developers/docs/resources/channel#create-channel-invite-json-params
]=]

local apiTypes = require("../lune_packages/api_types")

local Invite = {}

Invite.Prototype = {}
Invite.Interface = {}

--[=[
	@within Builders.Invite

	Sets the duration in seconds after which the invite expires.
	Age must be between 0 and 604800 seconds.
]=]
function Invite.Prototype.setMaxAge(self: Invite, age: number): Invite
	assert(age >= 0, "Max age must be greater than or equal to 0")
	assert(age <= 604800, "Max age must be less than or equal to 604800")

	self.maxAge = age

	return self
end

--[=[
	@within Builders.Invite

	Sets the maximum number of times this invite can be used.
	Uses must be between 0 and 100.
]=]
function Invite.Prototype.setMaxUses(self: Invite, uses: number): Invite
	assert(uses >= 0, "Max uses must be greater than or equal to 0")
	assert(uses <= 100, "Max uses must be less than or equal to 604800")

	self.maxUses = uses

	return self
end

--[=[
	@within Builders.Invite

	Sets whether the invite grants temporary membership.
	Temporary members are removed when they disconnect unless granted a role.
]=]
function Invite.Prototype.setTemporary(self: Invite, isTemporary: boolean): Invite
	self.temporary = isTemporary

	return self
end

--[=[
	@within Builders.Invite

	Sets whether this invite should be unique.
	If true, don't try to reuse a similar invite.
]=]
function Invite.Prototype.setIsUnique(self: Invite, isUnique: boolean): Invite
	self.unique = isUnique

	return self
end

--[=[
	@within Builders.Invite

	Sets the type of target for this invite.
	Used for stream and embedded application invites.
]=]
function Invite.Prototype.setTargetType(self: Invite, targetType: apiTypes.InviteTargetType): Invite
	assert(apiTypes.guild.InviteTargetType[targetType], "Invalid target type")

	self.targetType = targetType

	return self
end

--[=[
	@within Builders.Invite

	Sets the target user ID for this invite.
	Used to specify which user's stream to display for stream invites.
]=]
function Invite.Prototype.setTargetUser(self: Invite, userId: string): Invite
	self.targetUserId = userId

	return self
end

--[=[
	@within Builders.Invite

	Sets the target application ID for this invite.
	Used to specify which embedded application to open.
]=]
function Invite.Prototype.setTargetApplication(self: Invite, applicationId: string): Invite
	self.targetApplicationId = applicationId

	return self
end

--[=[
	@within Builders.Invite

	Responsible for buillding the invite object that the Discord API can understand.
]=]
function Invite.Prototype.build(self: Invite): JSON
	return {
		max_age = self.maxAge,
		max_uses = self.maxUses,
		temporary = self.temporary,
		unique = self.unique,
		target_type = apiTypes.guild.InviteTargetType[self.targetType],
		target_user_id = self.targetUserId,
		target_application_id = self.targetApplicationId,
	}
end

--[=[
	@within Builders.Invite

	Responsible for creating a new Invite.
]=]
function Invite.Interface.new(resource: {
	maxAge: number?,
	maxUses: number?,
	temporary: boolean?,
	unique: boolean?,
	targetType: apiTypes.InviteTargetType?,
	targetUserId: string?,
	targetApplicationId: string?,
}?): Invite
	local self = setmetatable(
		{
			--[=[
				@prop maxAge number?
				@within Builders.Invite
				Duration in seconds after which the invite expires. Must be between 0 and 604800 seconds.
			]=]

			--[=[
				@prop maxUses number?
				@within Builders.Invite
				Maximum number of times this invite can be used. Must be between 0 and 100.
			]=]

			--[=[
				@prop temporary boolean?
				@within Builders.Invite
				Whether the invite grants temporary membership. Members are removed on disconnect unless granted a role.
			]=]

			--[=[
				@prop unique boolean?
				@within Builders.Invite
				Whether this invite should be unique. If true, don't try to reuse a similar invite.
			]=]

			--[=[
				@prop targetType api_types.InviteTargetType?
				@within Builders.Invite
				The type of target for this invite. Used for stream and embedded application invites.
			]=]

			--[=[
				@prop targetUserId string?
				@within Builders.Invite
				The target user ID for this invite. Used to specify which user's stream to display.
			]=]

			--[=[
				@prop targetApplicationId string?
				@within Builders.Invite
				The target application ID for this invite. Used to specify which embedded application to open.
			]=]
		} :: Invite,
		{
			__index = Invite.Prototype,
		}
	)

	if resource then
		if resource.maxAge then
			self:setMaxAge(resource.maxAge)
		end

		if resource.maxUses then
			self:setMaxUses(resource.maxUses)
		end

		if resource.temporary then
			self:setTemporary(resource.temporary)
		end

		if resource.unique then
			self:setIsUnique(resource.unique)
		end

		if resource.targetType then
			self:setTargetType(resource.targetType)
		end

		if resource.targetUserId then
			self:setTargetUser(resource.targetUserId)
		end

		if resource.targetApplicationId then
			self:setTargetApplication(resource.targetApplicationId)
		end
	end

	return self
end

export type Invite = typeof(Invite.Prototype) & {
	maxAge: number?,
	maxUses: number?,
	temporary: boolean?,
	unique: boolean?,
	targetType: apiTypes.InviteTargetType?,
	targetUserId: string?,
	targetApplicationId: string?,
}

export type JSON = typeof(Invite.Prototype.build(nil :: any))

return Invite.Interface
