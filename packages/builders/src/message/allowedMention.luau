--[[
	Implementation of discords AllowedMention object as a Luau builder.	

	https://discord.com/developers/docs/resources/message#allowed-mentions-object
]]

local apiTypes = require("../../lune_packages/api_types")

local AllowedMention = {}

AllowedMention.Prototype = {}
AllowedMention.Interface = {}

--[[
	Add a user mention to the allowed mentions for this message.
]]
function AllowedMention.Prototype.addUserMention(self: AllowedMention, userId: string): AllowedMention
	if not table.find(self.parse, "users") then
		table.insert(self.parse, "users")
	end

	table.insert(self.users, userId)

	return self
end

--[[
	Add a role mention to the allowed mentions for this message.
]]
function AllowedMention.Prototype.addRoleMention(self: AllowedMention, roleId: string): AllowedMention
	if not table.find(self.parse, "roles") then
		table.insert(self.parse, "roles")
	end

	table.insert(self.roles, roleId)

	return self
end

--[[
	For replies, whether to mention the author of the message being replied to (default false)
]]
function AllowedMention.Prototype.setRepliedUser(self: AllowedMention, repliedUser: boolean): AllowedMention
	self.repliedUser = repliedUser

	return self
end

--[[
	Controls @everyone and @here mentions
]]
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

--[[
	Responsible for building the AllowedMention JSON that can be parsed by the Discord API.
]]
function AllowedMention.Prototype.build(self: AllowedMention): JSON
	return {
		parse = self.parse,
		roles = self.roles,
		users = self.users,
		replied_user = self.repliedUser,
	}
end

--[[
	Responsible for creating a new AllowedMention.

	```lua
	
	```
]]
function AllowedMention.Interface.new(resource: {
	roles: { apiTypes.Snowflake },
	users: { apiTypes.Snowflake },
	repliedUser: boolean?,
	mentionsEveryone: boolean?,
}?): AllowedMention
	local self = setmetatable(
		{
			parse = {},
			roles = {},
			users = {},
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
