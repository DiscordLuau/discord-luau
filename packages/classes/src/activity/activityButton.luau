--[=[
	@class Classes.Activity.Button
	@__index Prototype

	Implementation of the Discord ActivityButton class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-buttons
]=]

--[=[
	@prop label string
	@within Classes.Activity.Button

	The text shown on the button (1-32 characters)
]=]

--[=[
	@prop url string
	@within Classes.Activity.Button

	The url opened when clicking the button (1-512 characters)
]=]

local ActivityButton = {}

ActivityButton.Interface = {}
ActivityButton.Prototype = {}

--[=[
	@within Classes.Activity.Button
	@private

	Responsible for constructing this class.
]=]
function ActivityButton.Interface.new(label: string, url: string): ActivityButton
	local self = setmetatable(
		{
			label = label,

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
