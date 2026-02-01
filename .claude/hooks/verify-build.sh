#!/usr/bin/env bash
# Stop hook for /publish skill - verifies build passes before Claude stops
#
# Exit codes:
#   0 = Allow the stop
#   2 = Block the stop (feedback shown to Claude)

set -euo pipefail

INPUT=$(cat)

# Prevent infinite loop - check stop_hook_active
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_ACTIVE" == "true" ]]; then
    exit 0
fi

# Run build
echo "Verifying build passes..." >&2
if ! npm run build 2>&1 | tee /tmp/build-verify.log; then
    echo "" >&2
    echo "BUILD FAILED - Fix errors before stopping:" >&2
    tail -20 /tmp/build-verify.log >&2
    exit 2  # Block stop
fi

echo "Build verified successfully." >&2
exit 0
