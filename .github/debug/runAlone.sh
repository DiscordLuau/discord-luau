#!/usr/bin/env bash
# Runs one spec of a package on its own, with the package's other specs held outside it, and kills the run after a
# time limit. Usage: runAlone.sh <package> <spec name> <seconds>
set -uo pipefail
package="$1"
name="$2"
seconds="$3"
tests="packages/$package/tests"
held="${RUNNER_TEMP:-/tmp}/held-$package"
mkdir -p "$held"
for other in "$tests"/*.spec.luau; do
	if [ "$other" != "$tests/$name.spec.luau" ]; then mv "$other" "$held/"; fi
done
perl -e 'alarm shift @ARGV; exec @ARGV' "$seconds" zune run .zune/test.luau "packages/$package"
code=$?
pkill -f 'zune run' || true
for other in "$held"/*.spec.luau; do
	if [ -e "$other" ]; then mv "$other" "$tests/"; fi
done
echo "RESULT $package/$name exit=$code (142 means killed after $seconds s)"
