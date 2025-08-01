--[=[
	@class Classes.Activity
	@__index Prototype

	Implementation of the Discord Activity class in Luau

	https://discord.com/developers/docs/topics/gateway-events#activity-object
]=]

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

--[=[
	@within Classes.Activity
	@private

	Responsible for syncing data to this activity object. This is typically called by the API when this object is
	created or updated.
]=]
function Activity.Prototype.sync(self: Activity, activityData: apiTypes.ActivityObject)
	local activityButtons = {}
	local activityType: ActivityType = "Playing"

	if activityData.buttons then
		for _, button in activityData.buttons do
			table.insert(activityButtons, activityButton.new(button.label, button.url))
		end
	end

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

	--[=[
		@prop name string
		@within Classes.Activity

		The name of the activity being performed
	]=]
	self.name = activityData.name

	--[=[
		@prop type ActivityType
		@within Classes.Activity

		The type of activity being performed
	]=]
	self.type = activityType

	--[=[
		@prop url string?
		@within Classes.Activity

		Stream URL, is validated when type is 1 (streaming)
	]=]
	self.url = activityData.url

	--[=[
		@prop createdAt number
		@within Classes.Activity

		Unix timestamp in milliseconds of when the activity was created
	]=]
	self.createdAt = activityData.created_at

	--[=[
		@prop timestamps Classes.ActivityTimestamp
		@within Classes.Activity

		Unix timestamps for start and/or end of the game
	]=]
	self.timestamps = activityData.timestamps
		and activityTimestamp.new(activityData.timestamps.start, activityData.timestamps["end"])

	--[=[
		@prop applicationId string
		@within Classes.Activity

		Application ID for the game
	]=]
	self.applicationId = activityData.application_id

	--[=[
		@prop details string?
		@within Classes.Activity

		What the player is currently doing
	]=]
	self.details = activityData.details

	--[=[
		@prop state string?
		@within Classes.Activity

		The user's current party status
	]=]
	self.state = activityData.state

	--[=[
		@prop emoji Classes.ActivityEmoji?
		@within Classes.Activity

		The emoji used for a custom status
	]=]
	self.emoji = activityData.emoji and activityEmoji.new(activityData.emoji.id, activityData.emoji)

	--[=[
		@prop party Classes.ActivityParty?
		@within Classes.Activity

		Information for the current party of the player
	]=]
	self.party = activityData.party
		and activityParty.new(activityData.party.id, activityData.party.size[1], activityData.party.size[2])

	--[=[
		@prop assets Classes.ActivityAssets?
		@within Classes.Activity

		Images for the presence and their hover texts
	]=]
	self.assets = activityData.assets
		and activityAssets.new(
			activityData.assets.large_image,
			activityData.assets.large_text,
			activityData.assets.small_image,
			activityData.assets.small_text
		)

	--[=[
		@prop secrets Classes.ActivitySecrets?
		@within Classes.Activity

		Secrets for Rich Presence joining and spectating
	]=]
	self.secrets = activityData.secrets
		and activitySecrets.new(activityData.secrets.join, activityData.secrets.spectate, activityData.secrets.match)

	--[=[
		@prop instance boolean?
		@within Classes.Activity

		Whether or not the activity is an instanced game session
	]=]
	self.instance = activityData.instance

	--[=[
		@prop flags number?
		@within Classes.Activity

		Activity flags ORd together, describes what the payload includes
	]=]
	self.flags = activityData.flags

	--[=[
		@prop buttons {Classes.ActivityButton}
		@within Classes.Activity

		Custom buttons shown in the Rich Presence
	]=]
	self.buttons = activityButtons
end

--[=[
	@within Classes.Activity
	@private

	Responsible for constructing this class.
]=]
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
