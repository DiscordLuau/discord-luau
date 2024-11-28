--[[
	Implementation of the Discord Option class in Luau

	https://discord.com/developers/docs/resources/guild#guild-onboarding-object-option-option-structure
]]

local apiTypes = require("../../../lune_packages/api_types")

local emoji = require("../../emoji")

local Option = {}

Option.Interface = {}
Option.Prototype = {}

function Option.Prototype.sync(self: Option, optionData: apiTypes.PromptOptionObject)
	self.id = optionData.id
	self.channelIds = optionData.channel_ids
	self.roleIds = optionData.role_ids
	self.emoji = optionData.emoji and emoji.new(optionData.emoji)
	self.title = optionData.title
	self.description = optionData.description
end

function Option.Interface.new(optionData: apiTypes.PromptOptionObject): Option
	local self = setmetatable({} :: Option, { __index = Option.Prototype })

	self:sync(optionData)

	return self
end

export type Option = typeof(Option.Prototype) & {
	id: apiTypes.Snowflake?,
	channelIds: { apiTypes.Snowflake },
	roleIds: { apiTypes.Snowflake },
	emoji: emoji.Emoji?,
	title: string?,
	description: string?,
}

return Option.Interface
