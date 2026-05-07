--[=[
	@class Types.voice.types

	Payload shapes for the Discord voice WebSocket protocol (v8).
	https://discord.com/developers/docs/topics/voice-connections
]=]

type VoicePayload<DATA> = {
	op: number,
	d: DATA,
}

export type EncryptionMode = "aead_aes256_gcm_rtpsize" | "aead_xchacha20_poly1305_rtpsize"

export type SpeakingFlags = number

export type VoiceHelloPayload = VoicePayload<{
	heartbeat_interval: number,
}>

export type VoiceReadyPayload = VoicePayload<{
	ssrc: number, -- Our assigned SSRC
	ip: string, -- Voice server UDP IP
	port: number, -- Voice server UDP port
	modes: { EncryptionMode }, -- Encryption modes supported by the server
	dave_protocol_version: number?, -- Non-zero when the channel supports DAVE E2EE
}>

export type VoiceSessionDescriptionPayload = VoicePayload<{
	mode: EncryptionMode, -- Negotiated encryption mode
	secret_key: { number }, -- 32-byte symmetric key as an array of unsigned ints
	dave_protocol_version: number?, -- Active DAVE protocol version (0 = disabled)
}>

export type VoiceHeartbeatACKPayload = VoicePayload<number>

export type VoiceResumedPayload = VoicePayload<{}>

export type VoiceSpeakingPayload = VoicePayload<{
	user_id: string,
	ssrc: number,
	speaking: SpeakingFlags,
}>

export type DaveProtocolPrepareEpochPayload = VoicePayload<{
	protocol_version: number,
	transition_id: number,
}>

export type DaveMlsExternalSenderPackagePayload = VoicePayload<{
	external_sender_package: string, -- base64-encoded MLS credential
}>

export type DaveMlsProposalsPayload = VoicePayload<{
	proposals: string, -- base64-encoded serialised proposals blob
	recognized_user_ids: { string },
}>

export type DaveMlsAnnounceCommitTransitionPayload = VoicePayload<{
	commit: string, -- base64-encoded MLS commit
	recognized_user_ids: { string },
	transition_id: number,
}>

export type DaveMlsWelcomePayload = VoicePayload<{
	welcome: string, -- base64-encoded MLS welcome
	recognized_user_ids: { string },
	transition_id: number,
}>

export type VoiceIdentifyPayload = VoicePayload<{
	server_id: string, -- Guild ID
	user_id: string,
	session_id: string, -- Session ID from VOICE_STATE_UPDATE
	token: string, -- Token from VOICE_SERVER_UPDATE
}>

export type VoiceSelectProtocolPayload = VoicePayload<{
	protocol: "udp",
	data: {
		address: string, -- Our external IP (from IP discovery)
		port: number, -- Our external port
		mode: EncryptionMode,
	},
}>

export type VoiceHeartbeatPayload = VoicePayload<number> -- nonce (ms timestamp)

export type VoiceSpeakingSendPayload = VoicePayload<{
	speaking: SpeakingFlags,
	delay: number, -- Should always be 0
	ssrc: number,
}>

export type VoiceResumePayload = VoicePayload<{
	server_id: string,
	session_id: string,
	token: string,
	seq_ack: number?,
}>

export type DaveProtocolTransitionReadyPayload = VoicePayload<{
	transition_id: number,
}>

export type DaveMlsKeyPackagePayload = VoicePayload<string> -- base64-encoded key package

export type DaveMlsCommitWelcomePayload = VoicePayload<string> -- base64-encoded commit+welcome blob

export type DaveMlsInvalidCommitWelcomePayload = VoicePayload<{
	transition_id: number,
}>

return {}
