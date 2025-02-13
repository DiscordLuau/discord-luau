--[[
	Implementation of discords WidgetSettings object as a Luau builder.	

	https://discord.com/developers/docs/resources/guild#guild-widget-settings-object
]]

local apiTypes = require("../../lune_packages/api_types")

local WidgetSettings = {}

WidgetSettings.Prototype = {}
WidgetSettings.Interface = {}

--[[
	Set whether the widget is enabled
]]
function WidgetSettings.Prototype.setEnabled(self: WidgetSettings, enabled: boolean): WidgetSettings
	self.enabled = enabled

	return self
end

--[[
	Set the widget channel id
]]
function WidgetSettings.Prototype.setChannelId(self: WidgetSettings, channelId: string): WidgetSettings
	self.channelId = channelId

	return self
end

--[[
	Responsible for building the WidgetSettingsObject JSON that can be parsed by the Discord API.
]]
function WidgetSettings.Prototype.build(self: WidgetSettings): JSON
	return {
		enabled = self.enabled,
		channel_id = self.channelId,
	}
end

--[[
	Responsible for creating a new WidgetSettings.

	```lua
	
	```
]]
function WidgetSettings.Interface.new(resource: {
	enabled: boolean?,
	channelId: string?,
}?): WidgetSettings
	local self = setmetatable({} :: WidgetSettings, {
		__index = WidgetSettings.Prototype,
	})

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
