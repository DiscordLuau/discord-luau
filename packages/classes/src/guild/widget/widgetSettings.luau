--[=[
	@class Classes.WidgetSettings
	@__index Prototype

	Implementation of the Discord WidgetSettings class in Luau

	https://discord.com/developers/docs/resources/guild#guild-widget-settings-object
]=]

local apiTypes = require("../../../lune_packages/api_types")

local WidgetSettings = {}

WidgetSettings.Interface = {}
WidgetSettings.Prototype = {}

--[=[
	@within Classes.WidgetSettings
	@private

	Responsible for syncing data to this widget settings object. This is typically called by the API when this object is
	created or updated.
]=]
function WidgetSettings.Prototype.sync(self: WidgetSettings, widgetSettingsData: apiTypes.GuildWidgetSettingsObject)
	--[=[
		@prop enabled boolean?
		@within Classes.WidgetSettings

		Whether the widget is enabled for this guild
	]=]
	self.enabled = widgetSettingsData.enabled

	--[=[
		@prop channelId string?
		@within Classes.WidgetSettings

		The channel id that the widget will generate an invite to, or null if set to no invite
	]=]
	self.channelId = widgetSettingsData.channel_id
end

--[=[
	@within Classes.WidgetSettings
	@private

	Responsible for constructing this class.
]=]
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
