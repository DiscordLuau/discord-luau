#!/usr/bin/env bash
# Cross-compiles native libraries on Linux x86_64 with a pinned zig and lays them out as
# packages/<package>/binaries/<os>-<arch>/lib<package><ext> under the output folder, with a SHA256SUMS file:
#   libopus:      linux x64/arm64 (built against glibc 2.17, so it loads on old distributions), macOS x64/arm64
#                 (macOS 11) and windows x64/x86, from the libopus source plus the settings shim in packages/opus/native
#   libsodium:    macOS x64/arm64
#   libsymphonia: linux x64/arm64 (glibc 2.17), macOS x64/arm64 and windows x64/x86, from the Rust crate in
#                 packages/symphonia/native with cargo zigbuild
# Every output is reproducible: a run on any Linux x86_64 machine gives the same bytes, because the script brings its
# own zig, checks the versions of zig, Rust and cargo-zigbuild, prints the cmake and make versions, and keeps debug
# info, build paths and timestamps out of the files.
# CI's binaries-match-recipe workflow runs this script on pull requests that touch the binaries or their sources, and
# fails when a committed file's sha256 differs from the rebuilt one.
# Needs cmake, make, curl, tar, xz, Rust through rustup (run `rustup toolchain install` in packages/symphonia/native
# for the pinned toolchain and targets) and cargo-zigbuild 0.24.0.
# Usage: bash .github/scripts/build-binaries.sh <output folder>
set -euo pipefail

ZIG_VERSION="0.16.0"
ZIG_SHA256="70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00"
CARGO_ZIGBUILD_VERSION="0.24.0"
OPUS_VERSION="1.6.1"
OPUS_SHA256="6ffcb593207be92584df15b32466ed64bbec99109f007c82205f0194572411a1"
SODIUM_VERSION="1.0.22"
SODIUM_SHA256="adbdd8f16149e81ac6078a03aca6fc03b592b89ef7b5ed83841c086191be3349"

if [[ "$(uname -s) $(uname -m)" != "Linux x86_64" ]]; then
	echo "build-binaries.sh runs on Linux x86_64 only, found $(uname -s) $(uname -m)" >&2
	exit 1
fi

cmake --version | head -1
make --version | head -1

outputDirectory=$(realpath -m "${1:?usage: build-binaries.sh <output folder>}")
repositoryDirectory=$(realpath "$(dirname "${BASH_SOURCE[0]}")/../..")
toolchainFile="$repositoryDirectory/packages/symphonia/native/rust-toolchain.toml"

foundCargoZigbuild=$(cargo-zigbuild --version 2>/dev/null || true)
if [[ "$foundCargoZigbuild" != "cargo-zigbuild $CARGO_ZIGBUILD_VERSION" ]]; then
	echo "build-binaries.sh needs cargo-zigbuild $CARGO_ZIGBUILD_VERSION, found ${foundCargoZigbuild:-none}" >&2
	exit 1
fi

if [[ ! "$(<"$toolchainFile")" =~ channel\ =\ \"([^\"]+)\" ]]; then
	echo "build-binaries.sh found no channel in $toolchainFile" >&2
	exit 1
fi
rustVersion=${BASH_REMATCH[1]}
foundRust=$(cd "$repositoryDirectory/packages/symphonia/native" && rustc --version 2>/dev/null || true)
if [[ "$foundRust" != "rustc $rustVersion "* ]]; then
	echo "build-binaries.sh needs Rust $rustVersion from rust-toolchain.toml, found ${foundRust:-none}" >&2
	exit 1
fi

workDirectory=$(mktemp -d)
trap 'rm -rf "$workDirectory"' EXIT
zigDirectory="$workDirectory/zig-x86_64-linux-$ZIG_VERSION"

for path in "$repositoryDirectory" "$workDirectory"; do
	if [[ "$path" == *" "* ]]; then
		echo "build-binaries.sh needs paths without spaces, because CMAKE_C_FLAGS would split -ffile-prefix-map, found '$path'" >&2
		exit 1
	fi
done

# ziglang.org asks CI to prefer its community mirrors; the sha256 check would make any mirror as safe as this URL.
curl -fsSL --retry 3 -o "$workDirectory/zig.tar.xz" "https://ziglang.org/download/$ZIG_VERSION/zig-x86_64-linux-$ZIG_VERSION.tar.xz"
curl -fsSL --retry 3 -o "$workDirectory/opus.tar.gz" "https://downloads.xiph.org/releases/opus/opus-$OPUS_VERSION.tar.gz"
curl -fsSL --retry 3 -o "$workDirectory/libsodium.tar.gz" "https://download.libsodium.org/libsodium/releases/libsodium-$SODIUM_VERSION.tar.gz"
echo "$ZIG_SHA256  $workDirectory/zig.tar.xz" | sha256sum -c -
echo "$OPUS_SHA256  $workDirectory/opus.tar.gz" | sha256sum -c -
echo "$SODIUM_SHA256  $workDirectory/libsodium.tar.gz" | sha256sum -c -
tar -xJf "$workDirectory/zig.tar.xz" -C "$workDirectory"
tar -xzf "$workDirectory/opus.tar.gz" -C "$workDirectory"
tar -xzf "$workDirectory/libsodium.tar.gz" -C "$workDirectory"

# cargo-zigbuild and `zig build` look zig up on PATH. A zig of the same version built differently (Arch's links the
# system LLVM) stamps other bytes, so this one comes first and keeps its own cache. cargo-zigbuild tries a Python
# ziglang package before PATH; CARGO_ZIGBUILD_ZIG_COMMAND, which its own linker wrappers set, skips that search. That
# variable is undocumented, so recheck it in cargo-zigbuild's src/zig/locate.rs whenever CARGO_ZIGBUILD_VERSION changes.
# The cargo-zigbuild cache is per run because the wrappers it writes there embed this run's zig path, and a shared
# cache would let two runs at once rewrite each other's wrappers.
export PATH="$zigDirectory:$PATH"
export ZIG_GLOBAL_CACHE_DIR="$workDirectory/zig-cache"
export CARGO_ZIGBUILD_CACHE_DIR="$workDirectory/cargo-zigbuild-cache"
export CARGO_ZIGBUILD_ZIG_COMMAND="$zigDirectory/zig"

foundZig=$("$zigDirectory/zig" version 2>/dev/null || true)
if [[ "$foundZig" != "$ZIG_VERSION" ]]; then
	echo "build-binaries.sh needs zig $ZIG_VERSION at $zigDirectory/zig, found ${foundZig:-none}" >&2
	exit 1
fi
foundZigPath=$(command -v zig || true)
if [[ "$foundZigPath" != "$zigDirectory/zig" ]]; then
	echo "build-binaries.sh needs $zigDirectory/zig first on PATH, found ${foundZigPath:-none}" >&2
	exit 1
fi

printf '#!/bin/sh\nexec zig ar "$@"\n' > "$workDirectory/ar"
printf '#!/bin/sh\nexec zig ranlib "$@"\n' > "$workDirectory/ranlib"
chmod +x "$workDirectory/ar" "$workDirectory/ranlib"

buildOpus() {
	local target="$1" system="$2" processor="$3" platform="$4" extension="$5"
	shift 5
	local compiler="$workDirectory/cc-$target"

	printf '#!/bin/sh\nexec zig cc -target %s "$@"\n' "$target" > "$compiler"
	chmod +x "$compiler"

	cmake -S "$repositoryDirectory/packages/opus/native" -B "$workDirectory/build-opus-$target" -G "Unix Makefiles" \
		-DOPUS_SOURCE_DIR="$workDirectory/opus-$OPUS_VERSION" \
		-DCMAKE_SYSTEM_NAME="$system" -DCMAKE_SYSTEM_PROCESSOR="$processor" \
		-DCMAKE_C_COMPILER="$compiler" -DCMAKE_AR="$workDirectory/ar" -DCMAKE_RANLIB="$workDirectory/ranlib" \
		-DCMAKE_C_FLAGS="-g0 -ffile-prefix-map=$workDirectory=. -ffile-prefix-map=$repositoryDirectory=." \
		-DCMAKE_SHARED_LINKER_FLAGS="-s" \
		-DCMAKE_BUILD_WITH_INSTALL_NAME_DIR=ON -DCMAKE_INSTALL_NAME_DIR=@rpath \
		-DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DOPUS_BUILD_PROGRAMS=OFF -DOPUS_BUILD_TESTING=OFF "$@"
	cmake --build "$workDirectory/build-opus-$target" -j "$(nproc)"
	mkdir -p "$outputDirectory/packages/opus/binaries/$platform"
	cp -L "$workDirectory/build-opus-$target/opus/libopus$extension" "$outputDirectory/packages/opus/binaries/$platform/libopus$extension"
}

buildSodium() {
	local target="$1" platform="$2"

	(cd "$workDirectory/libsodium-$SODIUM_VERSION" && zig build -Dtarget="$target" -Doptimize=ReleaseFast \
		-Dstatic=false -Dshared=true -Dtest=false --prefix "$workDirectory/install-sodium-$target")
	mkdir -p "$outputDirectory/packages/sodium/binaries/$platform"
	cp -L "$workDirectory/install-sodium-$target/lib/libsodium.dylib" "$outputDirectory/packages/sodium/binaries/$platform/libsodium.dylib"
}

buildSymphonia() {
	local target="$1" platform="$2" builtName="$3" extension="$4"
	shift 4
	local targetDirectory="$workDirectory/symphonia-target"

	local rustFlags flag
	rustFlags=$(printf '%s\x1f%s\x1f%s' "--remap-path-prefix=$HOME=~" \
		"--remap-path-prefix=${CARGO_HOME:-$HOME/.cargo}=~/.cargo" "--remap-path-prefix=$repositoryDirectory=.")
	for flag in "$@"; do
		rustFlags+=$'\x1f'"$flag"
	done

	(cd "$repositoryDirectory/packages/symphonia/native" && CARGO_TARGET_DIR="$targetDirectory" \
		CARGO_ENCODED_RUSTFLAGS="$rustFlags" cargo zigbuild --release --locked --target "$target")
	mkdir -p "$outputDirectory/packages/symphonia/binaries/$platform"
	cp -L "$targetDirectory/${target%.2.17}/release/$builtName" "$outputDirectory/packages/symphonia/binaries/$platform/libsymphonia$extension"
}

buildOpus x86_64-linux-gnu.2.17 Linux x86_64 linux-x64 .so
buildOpus aarch64-linux-gnu.2.17 Linux aarch64 linux-arm64 .so
buildOpus x86_64-macos.11.0 Darwin x86_64 macos-x64 .dylib
buildOpus aarch64-macos.11.0 Darwin arm64 macos-arm64 .dylib -DOPUS_PRESUME_NEON=ON
buildOpus x86_64-windows-gnu Windows AMD64 windows-x64 .dll
buildOpus x86-windows-gnu Windows x86 windows-x86 .dll
buildSodium x86_64-macos macos-x64
buildSodium aarch64-macos macos-arm64
buildSymphonia x86_64-unknown-linux-gnu.2.17 linux-x64 libdiscord_luau_symphonia.so .so
buildSymphonia aarch64-unknown-linux-gnu.2.17 linux-arm64 libdiscord_luau_symphonia.so .so
buildSymphonia x86_64-apple-darwin macos-x64 libdiscord_luau_symphonia.dylib .dylib -Clink-arg=-Wl,-S
buildSymphonia aarch64-apple-darwin macos-arm64 libdiscord_luau_symphonia.dylib .dylib -Clink-arg=-Wl,-S
buildSymphonia x86_64-pc-windows-gnu windows-x64 discord_luau_symphonia.dll .dll -Clink-arg=-Wl,-Brepro
buildSymphonia i686-pc-windows-gnu windows-x86 discord_luau_symphonia.dll .dll -Clink-arg=-Wl,-Brepro

(cd "$outputDirectory" && find packages -type f \( -name '*.so' -o -name '*.dylib' -o -name '*.dll' \) -exec sha256sum {} + | sort -k2 > SHA256SUMS)
cat "$outputDirectory/SHA256SUMS"
printf 'build-binaries.sh took %dm %02ds\n' $((SECONDS / 60)) $((SECONDS % 60))
