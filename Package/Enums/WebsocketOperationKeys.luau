-- https://discord.com/developers/docs/topics/gateway#gateway-events

local WebsocketOperationKeys = {
	OperationCode = "op",
	Data = "d",
	Sequence = "s",
	EventName = "t",
}

export type WebsocketOperationKeys = "op"
	| "d"
	| "s"
	| "t"

return WebsocketOperationKeys