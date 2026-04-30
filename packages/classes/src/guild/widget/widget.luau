--[=[
	@class Classes.Guild.Widget
	@__index Prototype

	Implementation of the Discord Widget class in Luau

	https://discord.com/developers/docs/resources/guild#guild-widget-settings-object
]=]

--[=[
	@prop id string
	@within Classes.Guild.Widget
	The unique identifier of this widget
]=]

--[=[
	@prop name string
	@within Classes.Guild.Widget
	The name of the widget
]=]

--[=[
	@prop instantInvite string?
	@within Classes.Guild.Widget
	The instant invite URL for this widget, if one exists
]=]

--[=[
	@prop channels { Classes.Channels.Channel }
	@within Classes.Guild.Widget
	Array of channels that are shown in the widget
]=]

--[=[
	@prop members { Classes.User }
	@within Classes.Guild.Widget
	Array of users that are shown in the widget
]=]

local apiTypes = require("../../../luau_packages/api_types")
local state = require("../../../luau_packages/state")

local user = require("../../user")

local constructChannelFromData = require("../../channels/construct")

local Widget = {}

Widget.Interface = {}
Widget.Prototype = {}

--[=[
	@within Classes.Guild.Widget
	@private

	Responsible for syncing data to this widget object. This is typically called by the API when this object is
	created or updated.
]=]
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

--[=[
	@within Classes.Guild.Widget
	@private

	Responsible for constructing this class.
]=]
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
