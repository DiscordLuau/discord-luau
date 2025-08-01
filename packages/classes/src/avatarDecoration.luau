--[=[
	@class Classes.AvatarDecoration
	@__index Prototype

	Implementation of the Discord Presence class in Luau

	https://discord.com/developers/docs/resources/user#avatar-decoration-data-object
]=]

local apiTypes = require("../lune_packages/api_types")

local AvatarDecoration = {}

AvatarDecoration.Interface = {}
AvatarDecoration.Prototype = {}

--[=[
	@within Classes.AvatarDecoration
	@private

	Responsible for constructing this class.
]=]
function AvatarDecoration.Interface.new(asset: string, skuId: apiTypes.Snowflake): AvatarDecoration
	local self = setmetatable(
		{
			--[=[
				@prop asset string
				@within Classes.AvatarDecoration
				The asset URL for this avatar decoration.
			]=]
			asset = asset,

			--[=[
				@prop skuId Snowflake
				@within Classes.AvatarDecoration
				The SKU ID for this avatar decoration.
			]=]
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
