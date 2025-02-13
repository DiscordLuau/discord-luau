--[[
	Implementation of the Discord Activity class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object
]]

local apiTypes = require("../../lune_packages/api_types")

local activityAssets = require("./activityAssets")
local activityButton = require("./activityButton")
local activitySecrets = require("./activitySecrets")
local activityEmoji = require("./activityEmoji")
local activityParty = require("./activityParty")
local activityTimestamp = require("./activityTimestamp")

local Activity = {}

Activity.Interface = {}
Activity.Prototype = {}

function Activity.Prototype.sync(self: Activity, activityData: apiTypes.ActivityObject)
	local activityButtons = {}
	local activityType: ActivityType = "Playing"

	if activityData.buttons then
		for _, button in activityData.buttons do
			table.insert(activityButtons, activityButton.new(button.label, button.url))
		end
	end

	self.party = activityData.party
		and activityParty.new(activityData.party.id, activityData.party.size[1], activityData.party.size[2])

	self.secrets = activityData.secrets
		and activitySecrets.new(activityData.secrets.join, activityData.secrets.spectate, activityData.secrets.match)

	self.timestamps = activityData.timestamps
		and activityTimestamp.new(activityData.timestamps.start, activityData.timestamps["end"])

	self.assets = activityData.assets
		and activityAssets.new(
			activityData.assets.large_image,
			activityData.assets.large_text,
			activityData.assets.small_image,
			activityData.assets.small_text
		)

	self.buttons = activityButtons

	if activityData.type == 0 then
		activityType = "Playing"
	elseif activityData.type == 1 then
		activityType = "Streaming"
	elseif activityData.type == 2 then
		activityType = "Listening"
	elseif activityData.type == 3 then
		activityType = "Watching"
	elseif activityData.type == 4 then
		activityType = "Custom"
	elseif activityData.type == 5 then
		activityType = "Competing"
	end

	self.name = activityData.name
	self.type = activityType
	self.url = activityData.url
	self.createdAt = activityData.created_at
	self.applicationId = activityData.application_id
	self.details = activityData.details
	self.state = activityData.state
	self.emoji = activityData.emoji and activityEmoji.new(activityData.emoji.id, activityData.emoji)
	self.instance = activityData.instance
	self.flags = activityData.flags
end

function Activity.Interface.new(data: apiTypes.ActivityObject): Activity
	local self = setmetatable({} :: Activity, { __index = Activity.Prototype })

	self:sync(data)

	return self
end

export type ActivityType = "Playing" | "Streaming" | "Listening" | "Watching" | "Custom" | "Competing"
export type Activity = typeof(Activity.Prototype) & {
	name: string,
	type: ActivityType,
	url: string?,
	createdAt: number,
	timestamps: activityTimestamp.ActivityTimestamp,
	applicationId: apiTypes.Snowflake,
	details: string?,
	state: string?,
	emoji: activityEmoji.ActivityEmoji?,
	party: activityParty.ActivityParty?,
	assets: activityAssets.ActivityAssets?,
	secrets: activitySecrets.ActivitySecrets?,
	instance: boolean?,
	flags: number?,
	buttons: { activityButton.ActivityButton },
}

return Activity.Interface
