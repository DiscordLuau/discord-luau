local apiTypes = require("@api-types/apiTypes")

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
