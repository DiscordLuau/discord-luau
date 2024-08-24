--[[
	Implementation of the Discord ActivityButton class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-buttons
]]

local ActivityButton = {}

ActivityButton.Interface = {}
ActivityButton.Prototype = {}

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
