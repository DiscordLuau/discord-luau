#!/usr/bin/env bash
# Checks that every native library a package's sys.luau expects can be downloaded from the
# release tag `binary.load` uses, and that its sha256 matches the checksum in sys.luau.
# A tag for a version that is not released yet does not exist until the release merges. A missing
# tag is reported as pending, and the file in this checkout is checked instead, only when the
# sys.luau version is newer (by sort -V) than every existing <package>-* tag. An older or equal
# version without a tag fails.
# Tags are read with `git ls-remote --tags origin`, because CI's checkout has none.
# Usage: bash .github/scripts/check-binary-tags.sh [--version <package>=<version> ...] [package ...]
#   (default packages: dave opus sodium symphonia)
# --version replaces the version read from that package's sys.luau; CI uses it to prove that an
# old version fails.
set -euo pipefail

packages=()
declare -A versionOverrides=()

while [ $# -gt 0 ]; do
	case "$1" in
		--version)
			if [ $# -lt 2 ] || [[ "$2" != *=* ]]; then
				echo "--version needs <package>=<version>"
				exit 2
			fi
			versionOverrides["${2%%=*}"]="${2#*=}"
			shift 2
			;;
		*)
			packages+=("$1")
			shift
			;;
	esac
done

if [ ${#packages[@]} -eq 0 ]; then
	packages=(dave opus sodium symphonia)
fi

workDirectory=$(mktemp -d)
trap 'rm -rf "$workDirectory"' EXIT
failures=0

for package in "${packages[@]}"; do
	sysFile="packages/$package/src/sys.luau"
	version=${versionOverrides[$package]:-$(grep -oE '^\s*version = "[^"]+"' "$sysFile" | head -1 | grep -oE '"[^"]+"' | tr -d '"')}
	urlTemplate=$(grep -oE 'url = "[^"]+"' "$sysFile" | head -1 | sed -E 's/^url = "(.*)"$/\1/')

	if ! remoteTags=$(git ls-remote --tags origin "refs/tags/$package-*"); then
		echo "FAIL $package: could not read tags with git ls-remote --tags origin"
		failures=$((failures + 1))
		continue
	fi
	existingVersions=$(printf '%s\n' "$remoteTags" | { grep -oE "refs/tags/$package-[^^ ]+" || true; } | sed -E "s#^refs/tags/$package-##")

	newestVersion=$(printf '%s\n' "$version" $existingVersions | sort -V | tail -1)
	pending=0
	if [ "$newestVersion" = "$version" ] && ! printf '%s\n' "$existingVersions" | grep -qxF "$version"; then
		pending=1
	fi

	while read -r platform checksum; do
		operatingSystem=${platform%-*}
		architecture=${platform#*-}
		case "$operatingSystem" in
			linux) extension=".so" ;;
			macos) extension=".dylib" ;;
			*) extension=".dll" ;;
		esac

		url=${urlTemplate//\{version\}/$version}
		url=${url//\{os\}/$operatingSystem}
		url=${url//\{arch\}/$architecture}
		url=${url//\{ext\}/$extension}
		downloadPath="$workDirectory/$package-$platform"
		source="tag $package-$version"

		if ! curl -fsSL --retry 3 -o "$downloadPath" "$url" 2>/dev/null; then
			checkoutPath="packages/$package/binaries/$platform/${url##*/}"

			if [ "$pending" -ne 1 ] || [ ! -f "$checkoutPath" ]; then
				echo "FAIL $package $platform: could not download $url"
				failures=$((failures + 1))
				continue
			fi

			cp "$checkoutPath" "$downloadPath"
			source="pending tag $package-$version, checked $checkoutPath"
		fi

		actual=$(sha256sum "$downloadPath" | cut -d' ' -f1)

		if [ "$actual" = "$checksum" ]; then
			echo "ok   $package $platform ($source)"
		else
			echo "FAIL $package $platform: $source has $actual, sys.luau expects $checksum"
			failures=$((failures + 1))
		fi
	done < <(grep -oE '\["[a-z0-9]+-[a-z0-9]+"\] = "sha256:[0-9a-f]{64}"' "$sysFile" | sed -E 's/^\["([^"]+)"\] = "sha256:([0-9a-f]+)"$/\1 \2/')
done

if [ "$failures" -gt 0 ]; then
	echo "$failures native librar(y/ies) do not match their release tag; point binary.load's version at a tag that holds the current files"
	exit 1
fi
