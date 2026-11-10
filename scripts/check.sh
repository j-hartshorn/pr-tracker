#!/bin/bash
# Runs the tests with the build noise filtered out.
set -uo pipefail
cd "$(dirname "$0")/.."

# With only the Command Line Tools, some test builds cannot find the Testing macro plugin. Building again finds it.
for attempt in 1 2 3 4 5; do
    output="$(swift test "$@" 2>&1)"
    status=$?
    grep -q "plugin for module 'TestingMacros' not found" <<<"$output" || break
done
grep -E "error|warning: [^s]|✘|recorded an issue|Test run with|Build failed" <<<"$output" | grep -v "search path"
exit "$status"
