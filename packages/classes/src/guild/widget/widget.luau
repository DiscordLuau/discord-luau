--[[
	Implementation of the Discord Widget class in Luau

	https://discord.com/developers/docs/resources/guild#guild-widget-settings-object
]]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local user = require("../../user")

local constructChannelFromData = require("../../channels/construct")

local Widget = {}

Widget.Interface = {}
Widget.Prototype = {}

function Widget.Prototype.sync(self: Widget, widgetData: apiTypes.GuildWidgetObject)
	local channelArray = {}
	local userArray = {}

	for _, channelData in widgetData.channels do
		table.insert(channelArray, constructChannelFromData(self.state, channelData) :: apiTypes.AbstractChannel)
	end

	for _, userData in widgetData.members do
		table.insert(userArray, user.new(userData))
	end

	self.id = widgetData.id
	self.name = widgetData.name
	self.instantInvite = widgetData.instant_invite
	self.channels = channelArray
	self.members = userArray
end

function Widget.Interface.new(state: state.State, widgetData: apiTypes.GuildWidgetObject): Widget
	local self = setmetatable(
		{
			state = state,
		} :: Widget,
		{ __index = Widget.Prototype }
	)

	self:sync(widgetData)

	return self
end

export type Widget = typeof(Widget.Prototype) & {
	state: state.State,

	id: string,
	name: string,
	instantInvite: string?,
	channels: { apiTypes.AbstractChannel },
	members: { user.User },
	presenceCount: number,
}

return Widget.Interface
