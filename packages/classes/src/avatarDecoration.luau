--[[
	Implementation of the Discord Presence class in Luau

	https://discord.com/developers/docs/resources/user#avatar-decoration-data-object
]]

local apiTypes = require("../lune_packages/api_types")

local AvatarDecoration = {}

AvatarDecoration.Interface = {}
AvatarDecoration.Prototype = {}

function AvatarDecoration.Interface.new(asset: string, skuId: apiTypes.Snowflake): AvatarDecoration
	local self = setmetatable(
		{
			asset = asset,
			skuId = skuId,
		} :: AvatarDecoration,
		{ __index = AvatarDecoration.Prototype }
	)

	return self
end

export type AvatarDecoration = typeof(AvatarDecoration.Prototype) & {
	asset: string,
	skuId: apiTypes.Snowflake,
}

return AvatarDecoration.Interface
