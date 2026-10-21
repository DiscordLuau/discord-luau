#!/usr/bin/env bash
# Checks that every native library a package's sys.luau expects can be downloaded from the
# release tag `binary.load` uses, and that its sha256 matches the checksum in sys.luau.
# Usage: bash .github/scripts/check-binary-tags.sh [package ...]   (default: dave opus sodium)
set -euo pipefail

packages=("$@")
if [ ${#packages[@]} -eq 0 ]; then
	packages=(dave opus sodium)
fi

workDirectory=$(mktemp -d)
trap 'rm -rf "$workDirectory"' EXIT
failures=0

for package in "${packages[@]}"; do
	sysFile="packages/$package/src/sys.luau"
	version=$(grep -oE '^\s*version = "[^"]+"' "$sysFile" | head -1 | grep -oE '"[^"]+"' | tr -d '"')
	urlTemplate=$(grep -oE 'url = "[^"]+"' "$sysFile" | head -1 | sed -E 's/^url = "(.*)"$/\1/')

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

		if ! curl -fsSL --retry 3 -o "$downloadPath" "$url"; then
			echo "FAIL $package $platform: could not download $url"
			failures=$((failures + 1))
			continue
		fi

		actual=$(sha256sum "$downloadPath" | cut -d' ' -f1)

		if [ "$actual" = "$checksum" ]; then
			echo "ok   $package $platform ($package-$version)"
		else
			echo "FAIL $package $platform: tag $package-$version serves $actual, sys.luau expects $checksum"
			failures=$((failures + 1))
		fi
	done < <(grep -oE '\["[a-z0-9]+-[a-z0-9]+"\] = "sha256:[0-9a-f]{64}"' "$sysFile" | sed -E 's/^\["([^"]+)"\] = "sha256:([0-9a-f]+)"$/\1 \2/')
done

if [ "$failures" -gt 0 ]; then
	echo "$failures native librar(y/ies) do not match their release tag; point binary.load's version at a tag that holds the current files"
	exit 1
fi
