#!/usr/bin/env bash
# Unpublish workflow: remove a published post from the blog repository
set -euo pipefail

# Colors for output (matching publish.sh)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Config file location
CONFIG_FILE=".claude/settings.local.json"

# Project paths
BLOG_DIR="src/content/blog"

# Exit codes
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_CANCELLED=130

# Script arguments
FILE_ARG=""
FORCE_MODE=false

# ============================================================================
# Argument Parsing
# ============================================================================

print_usage() {
    echo "Usage: $0 <file-or-slug> [--force|-f]"
    echo ""
    echo "Remove a published post from the blog repository."
    echo ""
    echo "Arguments:"
    echo "  file-or-slug  Path to post file or slug (e.g., my-post.md or my-post)"
    echo ""
    echo "Options:"
    echo "  --force, -f   Skip confirmation prompt"
    echo ""
    echo "Notes:"
    echo "  - Post is removed from blog repo but Obsidian source is untouched"
    echo "  - Images are left in repo (not removed)"
    echo "  - Changes are committed but NOT pushed"
    echo "  - Update post status in Obsidian to prevent re-publishing"
    exit 0
}

parse_args() {
    if [[ $# -eq 0 ]]; then
        echo -e "${RED}Error: Missing required argument${RESET}" >&2
        echo "" >&2
        print_usage
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f)
                FORCE_MODE=true
                shift
                ;;
            --help|-h)
                print_usage
                ;;
            -*)
                echo -e "${RED}Error: Unknown option: $1${RESET}" >&2
                print_usage
                ;;
            *)
                if [[ -z "$FILE_ARG" ]]; then
                    FILE_ARG="$1"
                else
                    echo -e "${RED}Error: Multiple file arguments not supported${RESET}" >&2
                    print_usage
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$FILE_ARG" ]]; then
        echo -e "${RED}Error: Missing required file or slug argument${RESET}" >&2
        print_usage
    fi
}

# ============================================================================
# Configuration
# ============================================================================

load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error: Config file not found: $CONFIG_FILE${RESET}" >&2
        echo -e "${YELLOW}Run 'just setup' first to configure your Obsidian vault path.${RESET}" >&2
        exit $EXIT_ERROR
    fi

    if ! command -v jq &>/dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${RESET}" >&2
        echo -e "${YELLOW}Install with: pacman -S jq (Arch) or brew install jq (macOS)${RESET}" >&2
        exit $EXIT_ERROR
    fi
}

# ============================================================================
# Utility Functions
# ============================================================================

slugify() {
    # Convert filename to slug: lowercase, spaces to hyphens, remove special chars
    local name="$1"
    # Remove .md extension if present
    name="${name%.md}"
    # Lowercase
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    # Replace spaces with hyphens
    name=$(echo "$name" | tr ' ' '-')
    # Remove special characters except hyphens
    name=$(echo "$name" | sed 's/[^a-z0-9-]//g')
    # Collapse multiple hyphens
    name=$(echo "$name" | sed 's/-\+/-/g')
    # Remove leading/trailing hyphens
    name=$(echo "$name" | sed 's/^-//' | sed 's/-$//')
    echo "$name"
}

extract_frontmatter_value() {
    # Extract a simple value from YAML frontmatter
    local file="$1"
    local key="$2"

    # Read until --- (end of frontmatter), grep for key, extract value
    sed -n '/^---$/,/^---$/p' "$file" | grep -E "^${key}:" | head -1 | sed "s/^${key}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//' | tr -d '\r'
}

# ============================================================================
# Post Resolution
# ============================================================================

find_post_in_blog() {
    # Find a post in the blog directory by slug
    # Returns the full path to the post file, or empty if not found
    local slug="$1"

    # Search for the post in all year directories
    local found_files=()
    while IFS= read -r -d '' file; do
        found_files+=("$file")
    done < <(find "$BLOG_DIR" -type f -name "${slug}.md" -print0 2>/dev/null)

    if [[ ${#found_files[@]} -eq 0 ]]; then
        return 1
    fi

    # Return the first match (should only be one)
    echo "${found_files[0]}"
    return 0
}

resolve_post_path() {
    # Resolve the input argument to a blog post path
    # Input can be a file path, filename, or slug
    local input="$1"
    local slug
    local post_path

    # Extract basename if input is a path
    if [[ "$input" == */* || "$input" == *.md ]]; then
        input=$(basename "$input")
    fi

    # Slugify to normalize
    slug=$(slugify "$input")

    # Find post in blog directory
    if post_path=$(find_post_in_blog "$slug"); then
        echo "$post_path"
        return 0
    fi

    # Not found
    echo -e "${RED}Error: Post not found in blog repository: $slug${RESET}" >&2
    echo -e "${YELLOW}Searched in: $BLOG_DIR${RESET}" >&2
    echo "" >&2
    echo "Tip: Use 'just list-posts --published' to see all published posts" >&2
    return 1
}

# ============================================================================
# Unpublish Functions
# ============================================================================

confirm_removal() {
    # Show post info and confirm removal (unless --force)
    local post_path="$1"
    local title

    # Extract title from frontmatter
    title=$(extract_frontmatter_value "$post_path" "title")
    if [[ -z "$title" ]]; then
        title=$(basename "$post_path" .md)
    fi

    # Display post info
    echo ""
    echo -e "${CYAN}Remove from blog:${RESET} \"$title\""
    echo -e "  ${CYAN}Path:${RESET} $post_path"
    echo ""

    # Skip prompt if --force
    if [[ "$FORCE_MODE" == "true" ]]; then
        return 0
    fi

    # Prompt for confirmation (default No for safety)
    read -rp "Proceed with removal? [y/N] " response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}Cancelled. Post not removed.${RESET}"
        exit $EXIT_SUCCESS
    fi

    return 0
}

remove_post() {
    # Remove post from blog and commit
    local post_path="$1"
    local title

    # Extract title for commit message
    title=$(extract_frontmatter_value "$post_path" "title")
    if [[ -z "$title" ]]; then
        title=$(basename "$post_path" .md)
    fi

    echo ""
    echo -e "${CYAN}Removing post...${RESET}"

    # Remove file using git
    git rm "$post_path" --quiet

    # Create commit
    local commit_msg="docs(blog): unpublish $title"
    git commit -m "$commit_msg" --quiet

    echo -e "${GREEN}Post removed and committed${RESET}"
    echo ""
    echo -e "${CYAN}Commit:${RESET} $commit_msg"
}

display_next_steps() {
    # Display post-removal tips
    echo ""
    echo -e "${GREEN}Post removed from blog${RESET}"
    echo ""
    echo -e "${YELLOW}Note:${RESET} Update status in Obsidian to prevent re-publishing:"
    echo "  status:"
    echo -e "    - Draft  ${CYAN}(or remove - Published)${RESET}"
    echo ""
    echo -e "${CYAN}Changes committed locally. Run 'git push' when ready.${RESET}"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse arguments
    parse_args "$@"

    # Load configuration
    load_config

    # Resolve post path from input
    local post_path
    if ! post_path=$(resolve_post_path "$FILE_ARG"); then
        exit $EXIT_ERROR
    fi

    # Confirm removal
    confirm_removal "$post_path"

    # Remove post and commit
    remove_post "$post_path"

    # Display next steps
    display_next_steps

    exit $EXIT_SUCCESS
}

main "$@"
