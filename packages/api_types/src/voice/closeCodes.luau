--[=[
	@class Types.voice.closeCodes

	https://discord.com/developers/docs/topics/voice-connections#opcodes-and-status-codes-voice-close-event-codes
]=]

local CloseCodes = table.freeze({
	UnknownOpcode = 4001,
	FailedToDecodePayload = 4002,
	NotAuthenticated = 4003,
	AuthenticationFailed = 4004,
	AlreadyAuthenticated = 4005,
	SessionNoLongerValid = 4006,
	SessionTimeout = 4009,
	ServerNotFound = 4011,
	UnknownProtocol = 4012,
	Disconnected = 4014,
	VoiceServerCrashed = 4015,
	UnknownEncryptionMode = 4016,
	DaveProtocolRequired = 4017,
	BadRequest = 4020,
	DisconnectedRateLimited = 4021,
	DisconnectedCallTerminated = 4022,
})

export type CloseCode =
	"UnknownOpcode"
	| "FailedToDecodePayload"
	| "NotAuthenticated"
	| "AuthenticationFailed"
	| "AlreadyAuthenticated"
	| "SessionNoLongerValid"
	| "SessionTimeout"
	| "ServerNotFound"
	| "UnknownProtocol"
	| "Disconnected"
	| "VoiceServerCrashed"
	| "UnknownEncryptionMode"
	| "DaveProtocolRequired"
	| "BadRequest"
	| "DisconnectedRateLimited"
	| "DisconnectedCallTerminated"

return CloseCodes
