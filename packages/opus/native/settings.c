/*
 * Fixed-argument entry points for the encoder settings. opus_encoder_ctl is variadic, and Zune FFI cannot call a
 * variadic function correctly on every platform (on macOS arm64 variadic arguments go on the stack), so Luau calls
 * these instead and the compiler makes the variadic call.
 */
#include "opus.h"

OPUS_EXPORT int discord_luau_opus_encoder_set(OpusEncoder *encoder, int request, int value)
{
	switch (request) {
	case OPUS_SET_BITRATE_REQUEST:
	case OPUS_SET_VBR_REQUEST:
	case OPUS_SET_COMPLEXITY_REQUEST:
	case OPUS_SET_INBAND_FEC_REQUEST:
	case OPUS_SET_SIGNAL_REQUEST:
		return opus_encoder_ctl(encoder, request, (opus_int32)value);
	default:
		return OPUS_UNIMPLEMENTED;
	}
}

OPUS_EXPORT int discord_luau_opus_encoder_get(OpusEncoder *encoder, int request, opus_int32 *value)
{
	switch (request) {
	case OPUS_GET_BITRATE_REQUEST:
	case OPUS_GET_VBR_REQUEST:
	case OPUS_GET_COMPLEXITY_REQUEST:
	case OPUS_GET_INBAND_FEC_REQUEST:
	case OPUS_GET_SIGNAL_REQUEST:
		return opus_encoder_ctl(encoder, request, value);
	default:
		return OPUS_UNIMPLEMENTED;
	}
}
