#!/usr/bin/env bash
# Cross-compiles native libraries on Linux with zig cc and lays them out as
# packages/<package>/binaries/<os>-<arch>/lib<package><ext> under the output folder, with a SHA256SUMS file:
#   libopus:   linux x64/arm64 (built against glibc 2.17, so it loads on old distributions), macOS x64/arm64
#   libsodium: macOS x64/arm64
# Needs zig, cmake, curl and tar. Usage: bash .github/scripts/build-binaries.sh <output folder>
set -euo pipefail

OPUS_VERSION="1.6.1"
OPUS_SHA256="6ffcb593207be92584df15b32466ed64bbec99109f007c82205f0194572411a1"
SODIUM_VERSION="1.0.22"
SODIUM_SHA256="adbdd8f16149e81ac6078a03aca6fc03b592b89ef7b5ed83841c086191be3349"

outputDirectory=$(realpath -m "${1:?usage: build-binaries.sh <output folder>}")
workDirectory=$(mktemp -d)
trap 'rm -rf "$workDirectory"' EXIT

curl -fsSL --retry 3 -o "$workDirectory/opus.tar.gz" "https://downloads.xiph.org/releases/opus/opus-$OPUS_VERSION.tar.gz"
curl -fsSL --retry 3 -o "$workDirectory/libsodium.tar.gz" "https://download.libsodium.org/libsodium/releases/libsodium-$SODIUM_VERSION.tar.gz"
echo "$OPUS_SHA256  $workDirectory/opus.tar.gz" | sha256sum -c -
echo "$SODIUM_SHA256  $workDirectory/libsodium.tar.gz" | sha256sum -c -
tar -xzf "$workDirectory/opus.tar.gz" -C "$workDirectory"
tar -xzf "$workDirectory/libsodium.tar.gz" -C "$workDirectory"

printf '#!/bin/sh\nexec zig ar "$@"\n' > "$workDirectory/ar"
printf '#!/bin/sh\nexec zig ranlib "$@"\n' > "$workDirectory/ranlib"
chmod +x "$workDirectory/ar" "$workDirectory/ranlib"

buildOpus() {
	local target="$1" system="$2" processor="$3" platform="$4" extension="$5"
	local compiler="$workDirectory/cc-$target"

	printf '#!/bin/sh\nexec zig cc -target %s "$@"\n' "$target" > "$compiler"
	chmod +x "$compiler"

	cmake -S "$workDirectory/opus-$OPUS_VERSION" -B "$workDirectory/build-opus-$target" -G "Unix Makefiles" \
		-DCMAKE_SYSTEM_NAME="$system" -DCMAKE_SYSTEM_PROCESSOR="$processor" -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
		-DCMAKE_C_COMPILER="$compiler" -DCMAKE_AR="$workDirectory/ar" -DCMAKE_RANLIB="$workDirectory/ranlib" \
		-DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DOPUS_BUILD_PROGRAMS=OFF -DOPUS_BUILD_TESTING=OFF
	cmake --build "$workDirectory/build-opus-$target" -j "$(nproc)"
	mkdir -p "$outputDirectory/packages/opus/binaries/$platform"
	cp -L "$workDirectory/build-opus-$target/libopus$extension" "$outputDirectory/packages/opus/binaries/$platform/libopus$extension"
}

buildSodium() {
	local target="$1" platform="$2"

	(cd "$workDirectory/libsodium-$SODIUM_VERSION" && zig build -Dtarget="$target" -Doptimize=ReleaseFast \
		-Dstatic=false -Dshared=true -Dtest=false --prefix "$workDirectory/install-sodium-$target")
	mkdir -p "$outputDirectory/packages/sodium/binaries/$platform"
	cp -L "$workDirectory/install-sodium-$target/lib/libsodium.dylib" "$outputDirectory/packages/sodium/binaries/$platform/libsodium.dylib"
}

buildOpus x86_64-linux-gnu.2.17 Linux x86_64 linux-x64 .so
buildOpus aarch64-linux-gnu.2.17 Linux aarch64 linux-arm64 .so
buildOpus x86_64-macos Darwin x86_64 macos-x64 .dylib
buildOpus aarch64-macos Darwin arm64 macos-arm64 .dylib
buildSodium x86_64-macos macos-x64
buildSodium aarch64-macos macos-arm64

(cd "$outputDirectory" && find packages -type f \( -name '*.so' -o -name '*.dylib' \) -exec sha256sum {} + | sort -k2 > SHA256SUMS)
cat "$outputDirectory/SHA256SUMS"
