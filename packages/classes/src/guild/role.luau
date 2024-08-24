--[[
	Implementation of the Discord Role class in Luau

	https://discord.com/developers/docs/resources/emoji#emoji-resource
]]

local apiTypes = require("@api-types/apiTypes")

local roleTags = require("@classes/guild/roleTag")

local Role = {}

Role.Interface = {}
Role.Prototype = {}

--[[
	Checks if the role is in an onboarding prompt.
]]
function Role.Prototype.isInOnboardingPrompt(self: Role)
	return bit32.lshift(self.flags, 0) == 0
end

function Role.Prototype.sync(self: Role, emojiData: apiTypes.GuildRoleObject)
	local tagArray = {}

	-- fixme: need to use `next` iterator here to avoid LSP errors.
	for _, tagData in next, emojiData.tags or {} do
		table.insert(tagArray, roleTags.new(tagData))
	end

	self.tags = tagArray
	self.id = emojiData.id
	self.name = emojiData.name
	self.color = emojiData.color
	self.hoist = emojiData.hoist
	self.icon = emojiData.icon
	self.unicodeEmoji = emojiData.unicode_emoji
	self.position = emojiData.position
	self.permissions = emojiData.permissions
	self.managed = emojiData.managed
	self.mentionable = emojiData.mentionable
	self.flags = emojiData.flags
end

function Role.Interface.new(emojiData: apiTypes.GuildRoleObject): Role
	local self = setmetatable({} :: Role, { __index = Role.Prototype })

	self:sync(emojiData)

	return self
end

export type Role = typeof(Role.Prototype) & {
	id: apiTypes.Snowflake?,
	name: string,
	color: number,
	hoist: boolean,
	icon: string?,
	unicodeEmoji: string?,
	position: number,
	permissions: string,
	managed: boolean,
	mentionable: boolean,
	tags: { roleTags.RoleTag }?,
	flags: number,
}

return Role.Interface
