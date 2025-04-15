--[=[
	@class Builders.AllowedMention
	@__index Prototype

	Implementation of discords AllowedMention object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#allowed-mentions-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local AllowedMention = {}

AllowedMention.Prototype = {}
AllowedMention.Interface = {}

--[=[
	@within Builders.AllowedMention

	Add a user mention to the allowed mentions for this message.
]=]
function AllowedMention.Prototype.addUserMention(self: AllowedMention, userId: string): AllowedMention
	if not table.find(self.parse, "users") then
		table.insert(self.parse, "users")
	end

	table.insert(self.users, userId)

	return self
end

--[=[
	@within Builders.AllowedMention

	Add a role mention to the allowed mentions for this message.
]=]
function AllowedMention.Prototype.addRoleMention(self: AllowedMention, roleId: string): AllowedMention
	if not table.find(self.parse, "roles") then
		table.insert(self.parse, "roles")
	end

	table.insert(self.roles, roleId)

	return self
end

--[=[
	@within Builders.AllowedMention

	For replies, whether to mention the author of the message being replied to (default false)
]=]
function AllowedMention.Prototype.setRepliedUser(self: AllowedMention, repliedUser: boolean): AllowedMention
	self.repliedUser = repliedUser

	return self
end

--[=[
	@within Builders.AllowedMention

	Controls @everyone and @here mentions
]=]
function AllowedMention.Prototype.setMentionsEveryone(self: AllowedMention, mentionsEveryone: boolean): AllowedMention
	if mentionsEveryone then
		if not table.find(self.parse, "everyone") then
			table.insert(self.parse, "everyone")
		end
	else
		local index = table.find(self.parse, "everyone")

		if index then
			table.remove(self.parse, index)
		end
	end

	return self
end

--[=[
	@within Builders.AllowedMention

	Responsible for building the AllowedMention JSON that can be parsed by the Discord API.
]=]
function AllowedMention.Prototype.build(self: AllowedMention): JSON
	return {
		parse = self.parse,
		roles = self.roles,
		users = self.users,
		replied_user = self.repliedUser,
	}
end

--[=[
	@within Builders.AllowedMention

	Responsible for creating a new AllowedMention.
]=]
function AllowedMention.Interface.new(resource: {
	roles: { apiTypes.Snowflake },
	users: { apiTypes.Snowflake },
	repliedUser: boolean?,
	mentionsEveryone: boolean?,
}?): AllowedMention
	local self = setmetatable(
		{
			--[=[
				@prop parse { apiTypes.AllowedMentionTypes }
				@within Builders.AllowedMention
				An array of allowed mention types to parse from the content.
			]=]
			parse = {},

			--[=[
				@prop roles { string }
				@within Builders.AllowedMention
				Array of role_ids to mention (Max size of 100).
			]=]
			roles = {},

			--[=[
				@prop users { string }
				@within Builders.AllowedMention
				Array of user_ids to mention (Max size of 100).
			]=]
			users = {},

			--[=[
				@prop repliedUser boolean?
				@within Builders.AllowedMention
				For replies, whether to mention the author of the message being replied to.
			]=]
		} :: AllowedMention,
		{
			__index = AllowedMention.Prototype,
		}
	)

	if resource then
		if resource.roles then
			for _, roleId in resource.roles do
				self:addRoleMention(roleId)
			end
		end

		if resource.users then
			for _, userId in resource.users do
				self:addUserMention(userId)
			end
		end

		if resource.repliedUser then
			self:setRepliedUser(resource.repliedUser)
		end

		if resource.mentionsEveryone then
			self:setMentionsEveryone(resource.mentionsEveryone)
		end
	end

	return self
end

export type AllowedMention = typeof(AllowedMention.Prototype) & {
	parse: { apiTypes.AllowedMentionTypes },
	roles: { apiTypes.Snowflake },
	users: { apiTypes.Snowflake },
	repliedUser: boolean?,
}

export type JSON = typeof(AllowedMention.Prototype.build(nil :: any))

return AllowedMention.Interface
