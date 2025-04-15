--[=[
	@class Builders.Presence
	@__index Prototype

	Implementation of a Discord Presence as a Luau builder.
	
	https://discord.com/developers/docs/events/gateway-events#update-presence
]=]

local apiTypes = require("../lune_packages/api_types")

local activity = require("./activity")

local Presence = {}

Presence.Prototype = {}
Presence.Interface = {}

--[=[
	@within Builders.Presence
	@private

	Adds an activity to the presence.
]=]
function Presence.Prototype.addActivity(self: Presence, activity: activity.JSON): Presence
	table.insert(self.activities, activity)

	return self
end

--[=[
	@within Builders.Presence
	@private

	Sets the status of the presence.
]=]
function Presence.Prototype.setStatus(self: Presence, status: apiTypes.Status): Presence
	assert(
		apiTypes.client.Status[status],
		`Expected status to be any of the following: 'Online, DoNotDisturb, Idle, Invisible, Offline'`
	)

	self.status = status

	return self
end

--[=[
	@within Builders.Presence
	@private

	Sets whether the presence is AFK.
]=]
function Presence.Prototype.setAfk(self: Presence, isAfk: boolean): Presence
	self.afk = isAfk

	return self
end

--[=[
	@within Builders.Presence
	@private

	Sets the time since the presence was last updated.
]=]
function Presence.Prototype.setSince(self: Presence, delta: number): Presence
	self.since = delta

	return self
end

--[=[
	@within Builders.Presence
	@private

	Builds the presence object that can be sent to the Discord API.
]=]
function Presence.Prototype.build(self: Presence): JSON
	return {
		since = self.since or 0,
		activities = self.activities,
		afk = self.afk or false,
		status = self.status and apiTypes.client.Status[self.status] or "online",
	}
end

--[=[
	@within Builders.Presence
	@private

	Constructor for the Discord Presence Builder.
]=]
function Presence.Interface.new(resource: {
	status: string?,
	afk: boolean?,
	since: number?,
	activities: { activity.JSON }?,
}?): Presence
	local self = setmetatable(
		{
			--[=[
				@prop activities { Classes.Activity }
				@within Builders.Presence
				An array of activity objects that represent what the client is currently doing.
			]=]
			activities = {},

			--[=[
				@prop since number?
				@within Builders.Presence
				Unix timestamp (in milliseconds) of when the client went idle, or null if the client is not idle.
			]=]

			--[=[
				@prop afk boolean?
				@within Builders.Presence
				Whether or not the client is afk.
			]=]

			--[=[
				@prop status string?
				@within Builders.Presence
				The user's current status. Can be "online", "dnd", "idle", "invisible", or "offline".
			]=]
		} :: Presence,
		{ __index = Presence.Prototype }
	)

	if resource then
		if resource.status then
			self.status = resource.status
		end
		if resource.afk ~= nil then
			self.afk = resource.afk
		end
		if resource.since then
			self.since = resource.since
		end
		if resource.activities then
			self.activities = resource.activities
		end
	end

	return self
end

export type Presence = typeof(Presence.Prototype) & {
	activities: { activity.JSON },
	since: number?,
	afk: boolean?,
	status: string?,
}

export type JSON = typeof(Presence.Prototype.build(nil :: any))

return Presence.Interface
