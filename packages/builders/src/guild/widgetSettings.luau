--[=[
	@class Builders.WidgetSettings
	@__index Prototype

	Implementation of discords WidgetSettings object as a Luau builder.	

	https://discord.com/developers/docs/resources/guild#guild-widget-settings-object
]=]

local apiTypes = require("../../lune_packages/api_types")

local WidgetSettings = {}

WidgetSettings.Prototype = {}
WidgetSettings.Interface = {}

--[=[
	@within Builders.WidgetSettings

	Set whether the widget is enabled
]=]
function WidgetSettings.Prototype.setEnabled(self: WidgetSettings, enabled: boolean): WidgetSettings
	self.enabled = enabled

	return self
end

--[=[
	@within Builders.WidgetSettings

	Set the widget channel id
]=]
function WidgetSettings.Prototype.setChannelId(self: WidgetSettings, channelId: string): WidgetSettings
	self.channelId = channelId

	return self
end

--[=[
	@within Builders.WidgetSettings

	Responsible for building the WidgetSettingsObject JSON that can be parsed by the Discord API.
]=]
function WidgetSettings.Prototype.build(self: WidgetSettings): JSON
	return {
		enabled = self.enabled,
		channel_id = self.channelId,
	}
end

--[=[
	@within Builders.WidgetSettings

	Responsible for creating a new WidgetSettings.

	```luau
	local settings = WidgetSettings.new({
		enabled = true,
		channelId = "123456789"
	})
	```
]=]
function WidgetSettings.Interface.new(resource: {
	enabled: boolean?,
	channelId: string?,
}?): WidgetSettings
	local self = setmetatable(
		{
			--[=[
				@prop enabled boolean?
				@within Builders.WidgetSettings
				Whether the widget is enabled for the guild.
			]=]
			enabled = nil,

			--[=[
				@prop channelId string?
				@within Builders.WidgetSettings
				The channel id that the widget will generate an invite to.
			]=]
			channelId = nil,
		} :: WidgetSettings,
		{
			__index = WidgetSettings.Prototype,
		}
	)

	if resource then
		if resource.enabled then
			self:setEnabled(resource.enabled)
		end

		if resource.channelId then
			self:setChannelId(resource.channelId)
		end
	end

	return self
end

export type WidgetSettings = typeof(WidgetSettings.Prototype) & {
	enabled: boolean?,
	channelId: apiTypes.Snowflake?,
}

export type JSON = typeof(WidgetSettings.Prototype.build(nil :: any))

return WidgetSettings.Interface
