--[=[
	@class Types.webhook
]=]

local util = require("../lune_packages/util")

local WebhookType = table.freeze(util.tableReflect({
	Incoming = 1,
	ChannelFollower = 2,
	Application = 3,
}))

export type WebhookType = "Incoming" | "ChannelFollower" | "Application"

return {
	WebhookType = WebhookType,
}
