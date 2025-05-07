--[=[
	@class Types.gateway.sendEvents

	https://discord.com/developers/docs/topics/gateway-events#send-events

	these enums map to the `opcodes` module under `@api-types/gateway/optcodes.luau`
]=]

local SendEvents = table.freeze({
	Identify = "Identify",
	Resume = "Resume",
	Heartbeat = "Heartbeat",
	RequestGuildMembers = "RequestGuildMembers",
	UpdateVoiceState = "UpdateVoiceState",
	UpdatePresence = "UpdatePresence",
})

export type SendEvent = "Identify" | "Resume" | "Heartbeat" | "RequestGuildMembers" | "UpdateVoiceState" | "UpdatePresence"

return SendEvents
