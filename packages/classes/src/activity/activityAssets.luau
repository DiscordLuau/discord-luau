--[=[
	@class Classes.ActivityAssets
	@__index Prototype

	Implementation of the Discord ActivityAssets class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-assets
]=]

--[=[
	@prop largeImage string
	@within Classes.ActivityAssets

	The key for the large asset of the activity, usually a snowflake representing a custom image
]=]

--[=[
	@prop largeText string
	@within Classes.ActivityAssets

	Text displayed when hovering over the large image of the activity
]=]

--[=[
	@prop smallImage string
	@within Classes.ActivityAssets

	The key for the small asset of the activity, usually a snowflake representing a custom image
]=]

--[=[
	@prop smallText string
	@within Classes.ActivityAssets

	Text displayed when hovering over the small image of the activity
]=]

local ActivityAssets = {}

ActivityAssets.Interface = {}
ActivityAssets.Prototype = {}

--[=[
	@within Classes.ActivityAssets
	@private

	Responsible for constructing this class.
]=]
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
