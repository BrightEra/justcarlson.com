#!/usr/bin/env bash
# Git safety hook for Claude Code
# Blocks dangerous git operations that could cause data loss
#
# Exit codes:
#   0 = Allow the operation
#   2 = Block the operation (feedback shown to Claude)
#
# Note: Does NOT block branch -D or rebase (per project context decisions)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
RESET='\033[0m'

# Log file location
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/blocked-operations.log"

# Read JSON input from stdin (Claude passes tool input as JSON)
INPUT=$(cat)

# Extract command from tool_input.command using jq
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# If no command found, allow (not a bash tool call we care about)
if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# Function to block an operation
block_operation() {
    local pattern="$1"
    local description="$2"
    local risk="$3"

    # Log to file with timestamp
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$(date -Iseconds)] BLOCKED: $description" >> "$LOG_FILE"
    echo "  Command: $COMMAND" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    # Print error to stderr (shown to Claude)
    echo -e "${RED}BLOCKED:${RESET} $description" >&2
    echo "" >&2
    echo "$risk" >&2
    echo "" >&2

    exit 2
}

# Dangerous patterns to block
# Pattern: "regex pattern" "description" "risk explanation"

# Force push - overwrites remote history
if [[ "$COMMAND" =~ git[[:space:]]+push[[:space:]]+(.*[[:space:]])?--force([[:space:]]|$) ]] || \
   [[ "$COMMAND" =~ git[[:space:]]+push[[:space:]]+(.*[[:space:]])?-f([[:space:]]|$) ]]; then
    block_operation "force push" \
        "Force push detected" \
        "Force pushing overwrites remote history and can cause data loss for collaborators."
fi

# Hard reset - discards commits
if [[ "$COMMAND" =~ git[[:space:]]+reset[[:space:]]+(.*[[:space:]])?--hard([[:space:]]|$) ]]; then
    block_operation "reset --hard" \
        "Hard reset detected" \
        "Hard reset discards uncommitted changes and can move HEAD, causing data loss."
fi

# Checkout . - discards all unstaged changes
if [[ "$COMMAND" =~ git[[:space:]]+checkout[[:space:]]+\.([[:space:]]|$) ]]; then
    block_operation "checkout ." \
        "Checkout . detected" \
        "This discards all unstaged changes in the working directory."
fi

# Restore . - discards all unstaged changes
if [[ "$COMMAND" =~ git[[:space:]]+restore[[:space:]]+\.([[:space:]]|$) ]]; then
    block_operation "restore ." \
        "Restore . detected" \
        "This discards all unstaged changes in the working directory."
fi

# Clean -f - deletes untracked files
if [[ "$COMMAND" =~ git[[:space:]]+clean[[:space:]]+(.*[[:space:]])?-[[:alnum:]]*f ]]; then
    block_operation "clean -f" \
        "Clean with force detected" \
        "This permanently deletes untracked files that cannot be recovered."
fi

# If no patterns matched, allow the operation
exit 0
