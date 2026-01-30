#!/usr/bin/env bash
# Interactive setup for Obsidian vault path configuration
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Config file location
CONFIG_DIR=".claude"
CONFIG_FILE="$CONFIG_DIR/settings.local.json"

echo ""
echo "=== Obsidian Vault Setup ==="
echo ""

# Auto-detect Obsidian vaults in home directory
echo "Searching for Obsidian vaults..."
mapfile -t VAULTS < <(find "$HOME" -maxdepth 4 -type d -name ".obsidian" 2>/dev/null | while read -r obsidian_dir; do
    dirname "$obsidian_dir"
done | sort -u)

VAULT_PATH=""

if [[ ${#VAULTS[@]} -eq 0 ]]; then
    # No vaults found - prompt for manual entry
    echo -e "${YELLOW}No Obsidian vaults found.${RESET}"
    echo ""
    read -rp "Enter the path to your Obsidian vault: " VAULT_PATH

    # Validate the path
    if [[ ! -d "$VAULT_PATH" ]]; then
        echo -e "${RED}Error: Directory does not exist: $VAULT_PATH${RESET}" >&2
        exit 1
    fi
    if [[ ! -d "$VAULT_PATH/.obsidian" ]]; then
        echo -e "${RED}Error: Not an Obsidian vault (no .obsidian directory): $VAULT_PATH${RESET}" >&2
        exit 1
    fi

elif [[ ${#VAULTS[@]} -eq 1 ]]; then
    # Single vault found - confirm
    echo -e "Found vault: ${GREEN}${VAULTS[0]}${RESET}"
    echo ""
    read -rp "Use this vault? [Y/n] " CONFIRM
    CONFIRM=${CONFIRM:-Y}

    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        VAULT_PATH="${VAULTS[0]}"
    else
        read -rp "Enter the path to your Obsidian vault: " VAULT_PATH

        # Validate the path
        if [[ ! -d "$VAULT_PATH" ]]; then
            echo -e "${RED}Error: Directory does not exist: $VAULT_PATH${RESET}" >&2
            exit 1
        fi
        if [[ ! -d "$VAULT_PATH/.obsidian" ]]; then
            echo -e "${RED}Error: Not an Obsidian vault (no .obsidian directory): $VAULT_PATH${RESET}" >&2
            exit 1
        fi
    fi

else
    # Multiple vaults found - show numbered list
    echo "Found ${#VAULTS[@]} Obsidian vaults:"
    echo ""
    for i in "${!VAULTS[@]}"; do
        echo "  $((i + 1)). ${VAULTS[$i]}"
    done
    echo ""
    read -rp "Select vault (1-${#VAULTS[@]}) or 0 for manual entry: " SELECTION

    if [[ "$SELECTION" =~ ^[0-9]+$ ]]; then
        if [[ "$SELECTION" -eq 0 ]]; then
            read -rp "Enter the path to your Obsidian vault: " VAULT_PATH

            # Validate the path
            if [[ ! -d "$VAULT_PATH" ]]; then
                echo -e "${RED}Error: Directory does not exist: $VAULT_PATH${RESET}" >&2
                exit 1
            fi
            if [[ ! -d "$VAULT_PATH/.obsidian" ]]; then
                echo -e "${RED}Error: Not an Obsidian vault (no .obsidian directory): $VAULT_PATH${RESET}" >&2
                exit 1
            fi
        elif [[ "$SELECTION" -ge 1 && "$SELECTION" -le ${#VAULTS[@]} ]]; then
            VAULT_PATH="${VAULTS[$((SELECTION - 1))]}"
        else
            echo -e "${RED}Error: Invalid selection${RESET}" >&2
            exit 1
        fi
    else
        echo -e "${RED}Error: Please enter a number${RESET}" >&2
        exit 1
    fi
fi

# Ensure we have a vault path
if [[ -z "$VAULT_PATH" ]]; then
    echo -e "${RED}Error: No vault path selected${RESET}" >&2
    exit 1
fi

# Create config directory if needed
mkdir -p "$CONFIG_DIR"

# Write config file
# Use jq if available, otherwise fallback to echo
if command -v jq &>/dev/null; then
    jq -n --arg path "$VAULT_PATH" '{"obsidianVaultPath": $path}' > "$CONFIG_FILE"
else
    echo "{\"obsidianVaultPath\": \"$VAULT_PATH\"}" > "$CONFIG_FILE"
fi

echo ""
echo -e "${GREEN}Setup complete.${RESET}"
echo -e "Vault path: ${GREEN}$VAULT_PATH${RESET}"
echo ""
echo "Config saved to: $CONFIG_FILE (gitignored - local to this machine)"
echo ""
