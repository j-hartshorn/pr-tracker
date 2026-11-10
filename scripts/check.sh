#!/bin/bash
# Runs the tests with the build noise filtered out.
set -uo pipefail
cd "$(dirname "$0")/.."
swift test "$@" 2>&1 | grep -E "error|warning: [^s]|✘|recorded an issue|Test run with|Build failed" | grep -v "search path"
exit "${PIPESTATUS[0]}"
