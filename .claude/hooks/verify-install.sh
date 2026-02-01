#!/usr/bin/env bash
# Stop hook for /install skill - verifies setup is complete
#
# Exit codes:
#   0 = Allow the stop
#   2 = Block the stop (feedback shown to Claude)

set -euo pipefail

INPUT=$(cat)
CONFIG_FILE=".claude/settings.local.json"

# Prevent infinite loop
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_ACTIVE" == "true" ]]; then
    exit 0
fi

FAILED=0

# Check 1: Vault path configured
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "MISSING: Config file $CONFIG_FILE" >&2
    FAILED=1
elif ! jq -e '.obsidianVaultPath' "$CONFIG_FILE" >/dev/null 2>&1; then
    echo "MISSING: obsidianVaultPath in config" >&2
    FAILED=1
else
    echo "OK: Vault path configured" >&2
fi

# Check 2: Dependencies installed
if [[ ! -d "node_modules" ]]; then
    echo "MISSING: node_modules (run npm install)" >&2
    FAILED=1
else
    echo "OK: Dependencies installed" >&2
fi

# Check 3: Build passes
echo "Checking build..." >&2
if ! npm run build 2>&1 | tee /tmp/install-verify.log; then
    echo "FAILED: Build has errors" >&2
    FAILED=1
else
    echo "OK: Build passes" >&2
fi

if [[ "$FAILED" -eq 1 ]]; then
    echo "" >&2
    echo "Setup incomplete - fix issues above before stopping" >&2
    exit 2
fi

echo "Setup verified successfully." >&2
exit 0
