--[[
	Implementation of the Discord ActivityAssets class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-assets
]]

local ActivityAssets = {}

ActivityAssets.Interface = {}
ActivityAssets.Prototype = {}

function ActivityAssets.Interface.new(
	largeImage: string,
	largeText: string,
	smallImage: string,
	smallText: string
): ActivityAssets
	local self = setmetatable(
		{
			largeImage = largeImage,
			largeText = largeText,
			smallImage = smallImage,
			smallText = smallText,
		} :: ActivityAssets,
		{ __index = ActivityAssets.Prototype }
	)

	return self
end

export type ActivityAssets = typeof(ActivityAssets.Prototype) & {
	largeImage: string,
	largeText: string,
	smallImage: string,
	smallText: string,
}

return ActivityAssets.Interface
