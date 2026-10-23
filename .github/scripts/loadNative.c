/*
 * Load test for the native libraries this repository ships. It opens libopus, libsodium and
 * libsymphonia from a checkout, resolves every function each package's sys.luau binds, and for
 * libopus sets, reads back and uses a bitrate through the settings shim.
 * Used by the load-native-libraries job in .github/workflows/native.yml, on the platforms Zune can't run.
 *
 * Usage: loadNative [checkout folder] [library:symbol ...]
 * Each extra library:symbol is resolved too, so a missing one fails the run (opus, sodium or symphonia).
 * Keep the symbol lists in step with packages/{opus,sodium,symphonia}/src/sys.luau.
 */
#include <math.h>
#include <stdio.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
typedef HMODULE Library;
static Library openLibrary(const char *path)
{
	char converted[1024];
	size_t index = 0;
	for (; path[index] && index < sizeof(converted) - 1; index++) {
		converted[index] = path[index] == '/' ? '\\' : path[index];
	}
	converted[index] = 0;
	return LoadLibraryA(converted);
}
static void *findSymbol(Library library, const char *name) { return (void *)GetProcAddress(library, name); }
static void describeOpenError(char *buffer, size_t size)
{
	DWORD code = GetLastError();
	char message[256] = "";
	FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, NULL, code, 0, message, sizeof(message), NULL);
	for (size_t index = strlen(message); index > 0 && (message[index - 1] == '\r' || message[index - 1] == '\n' || message[index - 1] == ' '); index--) {
		message[index - 1] = 0;
	}
	snprintf(buffer, size, "error %lu: %s", (unsigned long)code, message);
}
#define EXTENSION ".dll"
#else
#include <dlfcn.h>
typedef void *Library;
static Library openLibrary(const char *path) { return dlopen(path, RTLD_NOW | RTLD_LOCAL); }
static void *findSymbol(Library library, const char *name) { return dlsym(library, name); }
static void describeOpenError(char *buffer, size_t size)
{
	const char *message = dlerror();
	snprintf(buffer, size, "%s", message ? message : "unknown error");
}
#ifdef __APPLE__
#define EXTENSION ".dylib"
#else
#define EXTENSION ".so"
#endif
#endif

#if defined(_WIN32) && defined(_WIN64)
#define PLATFORM "windows-x64"
#elif defined(_WIN32)
#define PLATFORM "windows-x86"
#elif defined(__linux__) && defined(__aarch64__)
#define PLATFORM "linux-arm64"
#elif defined(__linux__)
#define PLATFORM "linux-x64"
#elif defined(__APPLE__) && defined(__aarch64__)
#define PLATFORM "macos-arm64"
#else
#define PLATFORM "macos-x64"
#endif

typedef struct {
	const char *name;
	const char *const *symbols;
	int symbolCount;
} Package;

static const char *const opusSymbols[] = {
	"opus_encoder_create",
	"opus_encode",
	"opus_encoder_destroy",
	"opus_decoder_create",
	"opus_decode",
	"opus_decoder_destroy",
	"opus_strerror",
	"discord_luau_opus_encoder_set",
	"discord_luau_opus_encoder_get",
};

static const char *const sodiumSymbols[] = {
	"crypto_aead_aes256gcm_is_available",
	"crypto_aead_aes256gcm_keygen",
	"crypto_aead_aes256gcm_encrypt",
	"crypto_aead_aes256gcm_decrypt",
	"crypto_aead_aes256gcm_encrypt_detached",
	"crypto_aead_aes256gcm_decrypt_detached",
	"crypto_aead_chacha20poly1305_ietf_keygen",
	"crypto_aead_chacha20poly1305_ietf_encrypt",
	"crypto_aead_chacha20poly1305_ietf_decrypt",
	"crypto_aead_chacha20poly1305_ietf_encrypt_detached",
	"crypto_aead_chacha20poly1305_ietf_decrypt_detached",
	"crypto_aead_xchacha20poly1305_ietf_keygen",
	"crypto_aead_xchacha20poly1305_ietf_encrypt",
	"crypto_aead_xchacha20poly1305_ietf_decrypt",
	"crypto_aead_xchacha20poly1305_ietf_encrypt_detached",
	"crypto_aead_xchacha20poly1305_ietf_decrypt_detached",
	"crypto_secretbox_keygen",
	"crypto_secretbox_easy",
	"crypto_secretbox_open_easy",
	"crypto_secretbox_detached",
	"crypto_secretbox_open_detached",
	"crypto_box_keypair",
	"crypto_box_beforenm",
	"crypto_box_easy",
	"crypto_box_open_easy",
	"crypto_box_detached",
	"crypto_box_open_detached",
	"crypto_box_easy_afternm",
	"crypto_box_open_easy_afternm",
	"crypto_sign_keypair",
	"crypto_sign_ed25519_sk_to_pk",
	"crypto_sign_detached",
	"crypto_sign_verify_detached",
	"crypto_generichash_statebytes",
	"crypto_generichash",
	"crypto_generichash_init",
	"crypto_generichash_update",
	"crypto_generichash_final",
	"crypto_hash_sha256",
	"crypto_hash_sha512",
	"crypto_auth_keygen",
	"crypto_auth",
	"crypto_auth_verify",
	"crypto_kdf_keygen",
	"crypto_kdf_derive_from_key",
	"crypto_pwhash",
	"crypto_pwhash_str",
	"crypto_pwhash_str_verify",
	"crypto_pwhash_str_needs_rehash",
	"randombytes_buf",
	"randombytes_uniform",
	"sodium_init",
	"sodium_memcmp",
	"sodium_memzero",
	"sodium_bin2hex",
	"sodium_hex2bin",
	"sodium_base64_encoded_len",
	"sodium_bin2base64",
	"sodium_base642bin",
};

static const char *const symphoniaSymbols[] = {
	"symphonia_abi_version",
	"symphonia_open_memory",
	"symphonia_open_file",
	"symphonia_info",
	"symphonia_describe",
	"symphonia_read",
	"symphonia_read_packet",
	"symphonia_open_stream",
	"symphonia_push",
	"symphonia_finish",
	"symphonia_close",
	"symphonia_open_count",
	"symphonia_worker_count",
};

#define COUNT(array) ((int)(sizeof(array) / sizeof((array)[0])))

static const Package packages[] = {
	{ "opus", opusSymbols, COUNT(opusSymbols) },
	{ "sodium", sodiumSymbols, COUNT(sodiumSymbols) },
	{ "symphonia", symphoniaSymbols, COUNT(symphoniaSymbols) },
};

typedef void *(*EncoderCreate)(int, int, int, int *);
typedef int (*Encode)(void *, const short *, int, unsigned char *, int);
typedef void (*EncoderDestroy)(void *);
typedef int (*EncoderSet)(void *, int, int);
typedef int (*EncoderGet)(void *, int, int *);

static int failures = 0;

static void fail(const char *library, const char *what, const char *detail)
{
	printf("FAIL %s: %s%s%s\n", library, what, detail ? " " : "", detail ? detail : "");
	failures++;
}

static void check(int passed, const char *library, const char *what)
{
	if (passed) {
		printf("OK   %s: %s\n", library, what);
	} else {
		fail(library, what, NULL);
	}
}

static int checkOpusEncoder(Library library)
{
	EncoderCreate encoderCreate = (EncoderCreate)findSymbol(library, "opus_encoder_create");
	Encode encode = (Encode)findSymbol(library, "opus_encode");
	EncoderDestroy encoderDestroy = (EncoderDestroy)findSymbol(library, "opus_encoder_destroy");
	EncoderSet encoderSet = (EncoderSet)findSymbol(library, "discord_luau_opus_encoder_set");
	EncoderGet encoderGet = (EncoderGet)findSymbol(library, "discord_luau_opus_encoder_get");
	if (!encoderCreate || !encode || !encoderDestroy || !encoderSet || !encoderGet) {
		fail("opus", "encoder check skipped, symbols missing", NULL);
		return 0;
	}

	int error = 0;
	void *encoder = encoderCreate(48000, 2, 2049, &error);
	check(encoder != NULL && error == 0, "opus", "opus_encoder_create");
	if (!encoder) {
		return 0;
	}

	int value = 0;
	check(encoderSet(encoder, 4002, 128000) == 0, "opus", "discord_luau_opus_encoder_set(4002, 128000) returns 0");
	int status = encoderGet(encoder, 4003, &value);
	check(status == 0 && value == 128000, "opus", "discord_luau_opus_encoder_get(4003) reads back 128000");
	printf("     opus: bitrate read back %d\n", value);

	short pcm[960 * 2];
	unsigned char packet[4000];
	for (int index = 0; index < 960; index++) {
		short sample = (short)(sin(2 * 3.14159265358979 * 440 * (index / 48000.0)) * 12000);
		pcm[index * 2] = sample;
		pcm[index * 2 + 1] = sample;
	}
	int length = encode(encoder, pcm, 960, packet, (int)sizeof(packet));
	check(length > 0, "opus", "opus_encode encodes one 960-sample frame");
	printf("     opus: frame encoded to %d bytes\n", length);
	encoderDestroy(encoder);
	return 1;
}

int main(int argc, char **argv)
{
	const char *root = argc > 1 ? argv[1] : ".";
	printf("platform %s, checkout %s\n", PLATFORM, root);

	for (int packageIndex = 0; packageIndex < COUNT(packages); packageIndex++) {
		const Package *package = &packages[packageIndex];
		char path[1024];
		snprintf(path, sizeof(path), "%s/packages/%s/binaries/" PLATFORM "/lib%s" EXTENSION, root, package->name, package->name);

		Library library = openLibrary(path);
		if (!library) {
			char reason[512];
			describeOpenError(reason, sizeof(reason));
			char detail[1600];
			snprintf(detail, sizeof(detail), "could not open %s (%s)", path, reason);
			fail(package->name, "open", detail);
			continue;
		}
		check(1, package->name, "opened");

		int resolved = 0;
		for (int symbolIndex = 0; symbolIndex < package->symbolCount; symbolIndex++) {
			if (findSymbol(library, package->symbols[symbolIndex])) {
				resolved++;
			} else {
				char detail[256];
				snprintf(detail, sizeof(detail), "missing %s", package->symbols[symbolIndex]);
				fail(package->name, detail, NULL);
			}
		}
		printf("%s %s: resolved %d of %d symbols\n", resolved == package->symbolCount ? "OK  " : "FAIL", package->name, resolved, package->symbolCount);

		for (int argumentIndex = 2; argumentIndex < argc; argumentIndex++) {
			const char *separator = strchr(argv[argumentIndex], ':');
			if (!separator || strncmp(argv[argumentIndex], package->name, (size_t)(separator - argv[argumentIndex])) != 0 || package->name[separator - argv[argumentIndex]] != 0) {
				continue;
			}
			if (findSymbol(library, separator + 1)) {
				printf("OK   %s: extra symbol %s resolved\n", package->name, separator + 1);
			} else {
				char detail[256];
				snprintf(detail, sizeof(detail), "missing %s", separator + 1);
				fail(package->name, detail, NULL);
			}
		}

		if (strcmp(package->name, "opus") == 0) {
			checkOpusEncoder(library);
		}
	}

	printf("%s\n", failures ? "LOAD TEST FAILED" : "LOAD TEST PASSED");
	return failures ? 1 : 0;
}
