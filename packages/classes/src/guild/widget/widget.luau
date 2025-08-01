--[=[
	@class Classes.Widget
	@__index Prototype

	Implementation of the Discord Widget class in Luau

	https://discord.com/developers/docs/resources/guild#guild-widget-settings-object
]=]

local apiTypes = require("../../../lune_packages/api_types")
local state = require("../../../lune_packages/state")

local user = require("../../user")

local constructChannelFromData = require("../../channels/construct")

local Widget = {}

Widget.Interface = {}
Widget.Prototype = {}

--[=[
	@within Classes.Widget
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

	--[=[
		@prop id string
		@within Classes.Widget
		The unique identifier of this widget
	]=]
	self.id = widgetData.id

	--[=[
		@prop name string
		@within Classes.Widget
		The name of the widget
	]=]
	self.name = widgetData.name

	--[=[
		@prop instantInvite string?
		@within Classes.Widget
		The instant invite URL for this widget, if one exists
	]=]
	self.instantInvite = widgetData.instant_invite

	--[=[
		@prop channels { Classes.Channel }
		@within Classes.Widget
		Array of channels that are shown in the widget
	]=]
	self.channels = channelArray

	--[=[
		@prop members { Classes.User }
		@within Classes.Widget
		Array of users that are shown in the widget
	]=]
	self.members = userArray
end

--[=[
	@within Classes.Widget
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
