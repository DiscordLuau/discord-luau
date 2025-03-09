--[=[
	@class Types.client
]=]

local util = require("../lune_packages/util")

local ActivityType = table.freeze(util.tableReflect({
	Game = 0,
	Streaming = 1,
	Listening = 2,
	Watching = 3,
	Competing = 5,
}))

local Status = table.freeze(util.tableReflect({
	Online = "online",
	DoNotDisturb = "dnd",
	Idle = "idle",
	Invisible = "invisible",
	Offline = "offline",
}))

export type ActivityType = "Game" | "Streaming" | "Listening" | "Watching" | "Competing"
export type Status = "Online" | "DoNotDisturb" | "Idle" | "Invisible" | "Offline"

return {
	ActivityType = ActivityType,
	Status = Status,
}
