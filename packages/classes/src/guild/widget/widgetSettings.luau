--[[
	Implementation of the Discord WidgetSettings class in Luau

	https://discord.com/developers/docs/resources/guild#guild-widget-settings-object
]]

local apiTypes = require("../../../lune_packages/api_types")

local WidgetSettings = {}

WidgetSettings.Interface = {}
WidgetSettings.Prototype = {}

function WidgetSettings.Prototype.sync(self: WidgetSettings, widgetSettingsData: apiTypes.GuildWidgetSettingsObject)
	self.enabled = widgetSettingsData.enabled
	self.channelId = widgetSettingsData.channel_id
end

function WidgetSettings.Interface.new(widgetSettingsData: apiTypes.GuildWidgetSettingsObject): WidgetSettings
	local self = setmetatable({} :: WidgetSettings, { __index = WidgetSettings.Prototype })

	self:sync(widgetSettingsData)

	return self
end

export type WidgetSettings = typeof(WidgetSettings.Prototype) & {
	enabled: boolean?,
	channelId: apiTypes.Snowflake?,
}

return WidgetSettings.Interface
