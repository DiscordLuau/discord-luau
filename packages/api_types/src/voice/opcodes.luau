--[=[
	@class Types.voice.opcodes

	https://discord.com/developers/docs/topics/voice-connections#opcodes-and-status-codes
]=]

local Opcodes = table.freeze({
	Identify = 0,
	SelectProtocol = 1,
	Ready = 2,
	Heartbeat = 3,
	SessionDescription = 4,
	Speaking = 5,
	HeartbeatACK = 6,
	Resume = 7,
	Hello = 8,
	Resumed = 9,
	ClientsConnect = 11,
	Video = 12,
	ClientDisconnect = 13,
	SessionUpdate = 14,
	MediaSinkWants = 15,
	VoiceBackendVersion = 16,
	ChannelOptionsUpdate = 17,
	ClientFlags = 18,
	ClientPlatform = 20,

	DaveProtocolPrepareTransition = 21,
	DaveProtocolExecuteTransition = 22,
	DaveProtocolTransitionReady = 23,
	DaveProtocolPrepareEpoch = 24,
	DaveMlsExternalSenderPackage = 25,
	DaveMlsKeyPackage = 26,
	DaveMlsProposals = 27,
	DaveMlsCommitWelcome = 28,
	DaveMlsAnnounceCommitTransition = 29,
	DaveMlsWelcome = 30,
	DaveMlsInvalidCommitWelcome = 31,
})

export type Opcode =
	"Identify"
	| "SelectProtocol"
	| "Ready"
	| "Heartbeat"
	| "SessionDescription"
	| "Speaking"
	| "HeartbeatACK"
	| "Resume"
	| "Hello"
	| "Resumed"
	| "ClientsConnect"
	| "Video"
	| "ClientDisconnect"
	| "SessionUpdate"
	| "MediaSinkWants"
	| "VoiceBackendVersion"
	| "ChannelOptionsUpdate"
	| "ClientFlags"
	| "ClientPlatform"
	| "DaveProtocolPrepareTransition"
	| "DaveProtocolExecuteTransition"
	| "DaveProtocolTransitionReady"
	| "DaveProtocolPrepareEpoch"
	| "DaveMlsExternalSenderPackage"
	| "DaveMlsKeyPackage"
	| "DaveMlsProposals"
	| "DaveMlsCommitWelcome"
	| "DaveMlsAnnounceCommitTransition"
	| "DaveMlsWelcome"
	| "DaveMlsInvalidCommitWelcome"

return Opcodes
