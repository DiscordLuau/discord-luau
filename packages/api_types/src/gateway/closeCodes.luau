--[=[
	@class Types.gateway.closeCodes

	https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-gateway-close-event-codes
]=]

local CloseCodes = table.freeze({
	UnknownError = 4000,
	UnknownOpcode = 4001,
	DecodeError = 4002,
	NotAuthenticated = 4003,
	AuthenticationFailed = 4004,
	AlreadyAuthenticated = 4005,
	InvalidSeq = 4007,
	Ratelimited = 4008,
	SessionTimedOut = 4009,
	InvalidShard = 4010,
	ShardingRequired = 4011,
	InvalidAPIVersion = 4012,
	InvalidIntents = 4013,
	DisallowedIntents = 4014,
})

export type CloseCode =
	"UnknownError"
	| "UnknownOpcode"
	| "DecodeError"
	| "NotAuthenticated"
	| "AuthenticationFailed"
	| "AlreadyAuthenticated"
	| "InvalidSeq"
	| "Ratelimited"
	| "SessionTimedOut"
	| "InvalidShard"
	| "ShardingRequired"
	| "InvalidAPIVersion"
	| "InvalidIntents"
	| "DisallowedIntents"

return CloseCodes
