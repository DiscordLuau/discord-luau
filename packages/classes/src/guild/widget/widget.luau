--[[
	Implementation of the Discord Widget class in Luau

	https://discord.com/developers/docs/resources/guild#guild-widget-settings-object
]]

local apiTypes = require("@api-types/apiTypes")
local channelTypes = require("@api-types/channel")

local user = require("@classes/user")

local constructChannelFromData = require("@utils/constructChannelFromData")

local Widget = {}

Widget.Interface = {}
Widget.Prototype = {}

function Widget.Prototype.sync(self: Widget, widgetData: apiTypes.GuildWidgetObject)
	local channelArray = {}
	local userArray = {}

	for _, channelData in widgetData.channels do
		table.insert(channelArray, constructChannelFromData(channelData) :: channelTypes.AbstractChannel)
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

function Widget.Interface.new(widgetData: apiTypes.GuildWidgetObject): Widget
	local self = setmetatable({} :: Widget, { __index = Widget.Prototype })

	self:sync(widgetData)

	return self
end

export type Widget = typeof(Widget.Prototype) & {
	id: string,
	name: string,
	instantInvite: string?,
	channels: { channelTypes.AbstractChannel },
	members: { user.User },
	presenceCount: number,
}

return Widget.Interface
