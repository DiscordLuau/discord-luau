--[=[
	@class Classes.ActivityButton
	@__index Prototype

	Implementation of the Discord ActivityButton class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-buttons
]=]

local ActivityButton = {}

ActivityButton.Interface = {}
ActivityButton.Prototype = {}

--[=[
	@within Classes.ActivityButton
	@private

	Responsible for constructing this class.
]=]
function ActivityButton.Interface.new(label: string, url: string): ActivityButton
	local self = setmetatable(
		{
			--[=[
				@prop label string
				@within Classes.ActivityButton

				The text shown on the button (1-32 characters)
			]=]
			label = label,

			--[=[
				@prop url string
				@within Classes.ActivityButton

				The url opened when clicking the button (1-512 characters)
			]=]
			url = url,
		} :: ActivityButton,
		{ __index = ActivityButton.Prototype }
	)

	return self
end

export type ActivityButton = typeof(ActivityButton.Prototype) & {
	label: string,
	url: string,
}

return ActivityButton.Interface
