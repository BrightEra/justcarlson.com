#!/usr/bin/env bash
# Publish workflow: discover posts from Obsidian vault marked as Published
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Config file location (matches setup.sh)
CONFIG_FILE=".claude/settings.local.json"

# Project paths
BLOG_DIR="src/content/blog"

# Exit codes
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_CANCELLED=130

# Global arrays for post data
declare -a POST_FILES=()
declare -a POST_TITLES=()
declare -a POST_DATES=()
declare -a POST_DISPLAY=()
declare -a POST_IS_UPDATE=()
declare -a SELECTED_FILES=()

# ============================================================================
# Validation
# ============================================================================

# Associative array to store validation errors by file path
declare -A VALIDATION_ERRORS

extract_frontmatter() {
    # Extract YAML frontmatter content (between first two --- lines)
    local file="$1"
    sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

get_frontmatter_field() {
    # Extract a field value from frontmatter content
    # Handles both simple values and quoted strings
    local frontmatter="$1"
    local field="$2"

    # Match field: value or field: "value" or field: 'value'
    local value
    value=$(echo "$frontmatter" | grep -E "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//" | sed 's/^["\x27]//' | sed 's/["\x27]$//' | tr -d '\r')

    echo "$value"
}

validate_iso8601() {
    # Validate ISO 8601 datetime format: YYYY-MM-DDTHH:MM:SS or YYYY-MM-DD
    local datetime="$1"

    # Check full datetime: YYYY-MM-DDTHH:MM:SS (with optional timezone)
    if [[ "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        return 0
    fi

    # Check date only: YYYY-MM-DD
    if [[ "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 0
    fi

    return 1
}

validate_frontmatter() {
    # Validate a single file's frontmatter
    # Returns array of error messages (empty = valid)
    local file="$1"
    local errors=()

    # Extract frontmatter
    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    if [[ -z "$frontmatter" ]]; then
        errors+=("No frontmatter found (YAML block between --- markers)")
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    # Check required fields
    local title
    local pubDatetime
    local description

    title=$(get_frontmatter_field "$frontmatter" "title")
    pubDatetime=$(get_frontmatter_field "$frontmatter" "pubDatetime")
    description=$(get_frontmatter_field "$frontmatter" "description")

    # Validate title
    if [[ -z "$title" ]]; then
        errors+=("Missing title (required for SEO and display)")
    fi

    # Validate pubDatetime
    if [[ -z "$pubDatetime" ]]; then
        errors+=("Missing pubDatetime (required for post ordering and URLs)")
    elif ! validate_iso8601 "$pubDatetime"; then
        errors+=("Invalid pubDatetime format: '$pubDatetime' (expected YYYY-MM-DDTHH:MM:SS or YYYY-MM-DD)")
    fi

    # Validate description
    if [[ -z "$description" ]]; then
        errors+=("Missing description (required for SEO and previews)")
    fi

    # Output errors (one per line)
    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

validate_selected_posts() {
    # Validate all selected posts, collecting all errors (not fail-fast)
    echo ""
    echo -e "${CYAN}Validating selected posts...${RESET}"

    local valid_files=()
    local invalid_files=()
    local all_errors=""

    for file in "${SELECTED_FILES[@]}"; do
        local errors
        local filename
        filename=$(basename "$file")

        if errors=$(validate_frontmatter "$file"); then
            valid_files+=("$file")
        else
            invalid_files+=("$file")
            all_errors+="${YELLOW}$filename:${RESET}\n"
            while IFS= read -r error; do
                all_errors+="  ${RED}- $error${RESET}\n"
            done <<< "$errors"
            all_errors+="\n"
        fi
    done

    # Display all errors at once
    if [[ ${#invalid_files[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Validation errors found:${RESET}"
        echo ""
        echo -e "$all_errors"
    fi

    # Handle partial valid scenario
    if [[ ${#invalid_files[@]} -gt 0 && ${#valid_files[@]} -gt 0 ]]; then
        echo -e "${YELLOW}${#valid_files[@]} of ${#SELECTED_FILES[@]} posts are valid.${RESET}"
        read -rp "Publish the valid ones? [Y/n] " response

        if [[ "$response" =~ ^[Nn] ]]; then
            echo ""
            echo -e "${YELLOW}Cancelled. Fix validation errors and try again.${RESET}"
            exit $EXIT_SUCCESS
        fi

        # Continue with only valid files
        SELECTED_FILES=("${valid_files[@]}")
        echo ""
        echo -e "${GREEN}Continuing with ${#SELECTED_FILES[@]} valid post(s)${RESET}"
    elif [[ ${#invalid_files[@]} -gt 0 && ${#valid_files[@]} -eq 0 ]]; then
        echo -e "${RED}No valid posts to publish. Fix validation errors and try again.${RESET}"
        exit $EXIT_ERROR
    else
        echo -e "${GREEN}All ${#SELECTED_FILES[@]} post(s) passed validation${RESET}"
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

    VAULT_PATH=$(jq -r '.obsidianVaultPath // empty' "$CONFIG_FILE")

    if [[ -z "$VAULT_PATH" ]]; then
        echo -e "${RED}Error: Obsidian vault path not configured.${RESET}" >&2
        echo -e "${YELLOW}Run 'just setup' to configure your vault path.${RESET}" >&2
        exit $EXIT_ERROR
    fi

    if [[ ! -d "$VAULT_PATH" ]]; then
        echo -e "${RED}Error: Vault directory does not exist: $VAULT_PATH${RESET}" >&2
        echo -e "${YELLOW}Run 'just setup' to reconfigure your vault path.${RESET}" >&2
        exit $EXIT_ERROR
    fi

    echo -e "Vault: ${CYAN}$VAULT_PATH${RESET}"
}

# ============================================================================
# Post Discovery
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

get_existing_post_path() {
    # Find if a post with this slug already exists in blog directory
    local slug="$1"
    local pub_date="$2"  # Format: YYYY-MM-DD or full datetime

    # Extract year from pub_date
    local year="${pub_date:0:4}"

    # Check if file exists in year directory
    local existing_path="${BLOG_DIR}/${year}/${slug}.md"
    if [[ -f "$existing_path" ]]; then
        echo "$existing_path"
    fi
}

posts_are_identical() {
    # Compare Obsidian post content with existing blog post
    # Returns 0 if identical, 1 if different
    local obsidian_file="$1"
    local blog_file="$2"

    # For now, do a simple diff. Future enhancement could normalize frontmatter.
    diff -q "$obsidian_file" "$blog_file" &>/dev/null
}

discover_posts() {
    echo ""
    echo -e "${CYAN}Searching for posts...${RESET}"

    # Find all markdown files with status: - Published (case-insensitive)
    # The pattern matches YAML list format: status:\n  - Published
    local found_files=()

    while IFS= read -r -d '' file; do
        # Check if file contains status with Published value
        # Using perl for multiline matching: status:\s*\n\s*-\s*[Pp]ublished
        if perl -0777 -ne 'exit(!/status:\s*\n\s*-\s*[Pp]ublished/i)' "$file" 2>/dev/null; then
            found_files+=("$file")
        fi
    done < <(find "$VAULT_PATH" -name "*.md" -type f -print0 2>/dev/null)

    if [[ ${#found_files[@]} -eq 0 ]]; then
        return
    fi

    echo -e "Found ${GREEN}${#found_files[@]}${RESET} post(s) with Published status"
    echo ""

    # Process each found file
    for file in "${found_files[@]}"; do
        local title
        local pub_date
        local filename
        local slug
        local existing_path
        local is_update="false"

        # Extract metadata
        title=$(extract_frontmatter_value "$file" "title")
        pub_date=$(extract_frontmatter_value "$file" "pubDatetime")

        # Fallback: use filename as title if not set
        filename=$(basename "$file")
        if [[ -z "$title" ]]; then
            title="${filename%.md}"
        fi

        # Generate slug from filename
        slug=$(slugify "$filename")

        # Check if already published
        existing_path=$(get_existing_post_path "$slug" "$pub_date")

        if [[ -n "$existing_path" ]]; then
            # File exists - check if identical
            if posts_are_identical "$file" "$existing_path"; then
                # Identical - skip this post
                continue
            else
                # Different - mark as update
                is_update="true"
            fi
        fi

        # Format date for display (extract YYYY-MM-DD)
        local display_date="${pub_date:0:10}"
        if [[ -z "$display_date" || "$display_date" == "null" ]]; then
            display_date="(no date)"
        fi

        # Add to arrays
        POST_FILES+=("$file")
        POST_TITLES+=("$title")
        POST_DATES+=("$pub_date")
        POST_IS_UPDATE+=("$is_update")

        # Create display string
        local display="$title - $display_date"
        if [[ "$is_update" == "true" ]]; then
            display="$display (update)"
        fi
        POST_DISPLAY+=("$display")
    done

    # Sort by date descending (newest first)
    # Create array of "date|index" pairs, sort, then reorder
    if [[ ${#POST_FILES[@]} -gt 1 ]]; then
        local sorted_indices=()
        local date_index_pairs=()

        for i in "${!POST_DATES[@]}"; do
            date_index_pairs+=("${POST_DATES[$i]}|$i")
        done

        # Sort descending by date
        mapfile -t sorted_pairs < <(printf '%s\n' "${date_index_pairs[@]}" | sort -t'|' -k1 -r)

        # Extract sorted indices
        for pair in "${sorted_pairs[@]}"; do
            sorted_indices+=("${pair##*|}")
        done

        # Reorder all arrays
        local new_files=() new_titles=() new_dates=() new_display=() new_updates=()
        for idx in "${sorted_indices[@]}"; do
            new_files+=("${POST_FILES[$idx]}")
            new_titles+=("${POST_TITLES[$idx]}")
            new_dates+=("${POST_DATES[$idx]}")
            new_display+=("${POST_DISPLAY[$idx]}")
            new_updates+=("${POST_IS_UPDATE[$idx]}")
        done

        POST_FILES=("${new_files[@]}")
        POST_TITLES=("${new_titles[@]}")
        POST_DATES=("${new_dates[@]}")
        POST_DISPLAY=("${new_display[@]}")
        POST_IS_UPDATE=("${new_updates[@]}")
    fi
}

# ============================================================================
# Interactive Selection
# ============================================================================

select_posts_gum() {
    # Use gum for checkbox-style multi-select
    local selected

    # Build display options
    selected=$(printf '%s\n' "${POST_DISPLAY[@]}" | gum choose --no-limit --header="Select posts to publish (space to toggle, enter to confirm):")

    if [[ -z "$selected" ]]; then
        return 1
    fi

    # Map selected display strings back to file paths
    while IFS= read -r display_line; do
        for i in "${!POST_DISPLAY[@]}"; do
            if [[ "${POST_DISPLAY[$i]}" == "$display_line" ]]; then
                SELECTED_FILES+=("${POST_FILES[$i]}")
                break
            fi
        done
    done <<< "$selected"

    return 0
}

select_posts_fzf() {
    # Fallback to fzf for multi-select
    local selected

    selected=$(printf '%s\n' "${POST_DISPLAY[@]}" | fzf --multi --header="Select posts (TAB to toggle, ENTER to confirm)")

    if [[ -z "$selected" ]]; then
        return 1
    fi

    # Map selected display strings back to file paths
    while IFS= read -r display_line; do
        for i in "${!POST_DISPLAY[@]}"; do
            if [[ "${POST_DISPLAY[$i]}" == "$display_line" ]]; then
                SELECTED_FILES+=("${POST_FILES[$i]}")
                break
            fi
        done
    done <<< "$selected"

    return 0
}

select_posts_numbered() {
    # Fallback to numbered list selection
    echo "Available posts:"
    echo ""

    for i in "${!POST_DISPLAY[@]}"; do
        echo "  $((i + 1)). ${POST_DISPLAY[$i]}"
    done

    echo ""
    echo "Enter post numbers to publish (comma-separated, e.g., 1,3,5)"
    echo "Or 'all' to publish all, 'q' to cancel"
    read -rp "> " selection

    if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
        return 1
    fi

    if [[ "$selection" == "all" || "$selection" == "ALL" ]]; then
        SELECTED_FILES=("${POST_FILES[@]}")
        return 0
    fi

    # Parse comma-separated numbers
    IFS=',' read -ra nums <<< "$selection"
    for num in "${nums[@]}"; do
        # Trim whitespace
        num=$(echo "$num" | tr -d ' ')
        if [[ "$num" =~ ^[0-9]+$ ]]; then
            local idx=$((num - 1))
            if [[ $idx -ge 0 && $idx -lt ${#POST_FILES[@]} ]]; then
                SELECTED_FILES+=("${POST_FILES[$idx]}")
            else
                echo -e "${YELLOW}Warning: Invalid number $num (skipping)${RESET}"
            fi
        fi
    done

    if [[ ${#SELECTED_FILES[@]} -eq 0 ]]; then
        return 1
    fi

    return 0
}

select_posts() {
    echo "Select posts to publish:"
    echo ""

    # Try selection methods in order of preference
    if command -v gum &>/dev/null; then
        if select_posts_gum; then
            return 0
        fi
    elif command -v fzf &>/dev/null; then
        if select_posts_fzf; then
            return 0
        fi
    else
        if select_posts_numbered; then
            return 0
        fi
    fi

    return 1
}

# ============================================================================
# Image Handling
# ============================================================================

# Asset directory for blog images
ASSETS_DIR="public/assets/blog"

extract_images() {
    # Extract image references from post content
    # Returns array of image filenames (local images only)
    local content="$1"
    local images=()

    # Find wiki-style images: ![[image.png]] or ![[image.png|alt text]]
    while IFS= read -r match; do
        if [[ -n "$match" ]]; then
            # Remove any alt text after |
            local img="${match%%|*}"
            images+=("$img")
        fi
    done < <(echo "$content" | grep -oP '!\[\[\K[^\]]+(?=\]\])' || true)

    # Find markdown-style local images: ![alt](path) - skip http/https URLs
    while IFS= read -r match; do
        if [[ -n "$match" && ! "$match" =~ ^https?:// ]]; then
            # Extract just the filename from path
            local img="${match##*/}"
            images+=("$img")
        fi
    done < <(echo "$content" | grep -oP '!\[[^\]]*\]\(\K[^)]+(?=\))' || true)

    # Output unique images
    printf '%s\n' "${images[@]}" | sort -u
}

find_local_image() {
    # Find an image file in the vault's Attachments folder
    local image="$1"
    local vault="$2"

    # Primary location: Attachments folder
    local attachments_path="${vault}/Attachments/${image}"
    if [[ -f "$attachments_path" ]]; then
        echo "$attachments_path"
        return 0
    fi

    # Fallback: search recursively in vault (for images in subdirectories)
    local found
    found=$(find "$vault" -name "$image" -type f 2>/dev/null | head -1)
    if [[ -n "$found" ]]; then
        echo "$found"
        return 0
    fi

    return 1
}

convert_wiki_links() {
    # Convert wiki-style image links to markdown format
    # Takes content and slug, returns converted content
    local content="$1"
    local slug="$2"

    # Convert ![[image.png]] to ![image.png](/assets/blog/slug/image.png)
    # Also handle ![[image.png|alt text]] to ![alt text](/assets/blog/slug/image.png)
    content=$(echo "$content" | perl -pe 's/!\[\[([^|\]]+)\|([^\]]+)\]\]/![$2](\/assets\/blog\/'"$slug"'\/$1)/g')
    content=$(echo "$content" | perl -pe 's/!\[\[([^\]]+)\]\]/![$1](\/assets\/blog\/'"$slug"'\/$1)/g')

    # Rewrite local markdown image paths (not http/https) to use asset directory
    # ![alt](image.png) or ![alt](./image.png) -> ![alt](/assets/blog/slug/image.png)
    content=$(echo "$content" | perl -pe 's/!\[([^\]]*)\]\((?!https?:\/\/)(?:\.\/)?([^\/\)]+)\)/![$1](\/assets\/blog\/'"$slug"'\/$2)/g')

    echo "$content"
}

copy_images() {
    # Copy images to public assets directory
    local slug="$1"
    shift
    local images=("$@")

    if [[ ${#images[@]} -eq 0 ]]; then
        return 0
    fi

    local dest_dir="${ASSETS_DIR}/${slug}"
    mkdir -p "$dest_dir"

    for image in "${images[@]}"; do
        local source_path
        if source_path=$(find_local_image "$image" "$VAULT_PATH"); then
            cp "$source_path" "$dest_dir/"
            echo -e "  ${GREEN}Copied:${RESET} $image"
        else
            echo -e "  ${YELLOW}Warning: Image not found: $image${RESET}"
        fi
    done
}

copy_post() {
    # Copy and transform a post to the blog directory
    local source_path="$1"
    local slug="$2"
    local year="$3"

    local dest_dir="${BLOG_DIR}/${year}"
    local dest_path="${dest_dir}/${slug}.md"

    # Create year directory if needed
    mkdir -p "$dest_dir"

    # Read content
    local content
    content=$(cat "$source_path")

    # Convert wiki-links to markdown
    content=$(convert_wiki_links "$content" "$slug")

    # Write to destination
    echo "$content" > "$dest_path"
}

process_posts() {
    # Process all selected posts: extract images, copy, transform
    echo ""
    echo -e "${CYAN}Processing posts...${RESET}"

    for file in "${SELECTED_FILES[@]}"; do
        local filename
        local slug
        local title
        local pub_date
        local year

        filename=$(basename "$file")
        slug=$(slugify "$filename")
        title=$(extract_frontmatter_value "$file" "title")
        pub_date=$(extract_frontmatter_value "$file" "pubDatetime")
        year="${pub_date:0:4}"

        echo ""
        echo -e "${CYAN}Processing:${RESET} $title"

        # Read content
        local content
        content=$(cat "$file")

        # Extract and copy images
        local images=()
        while IFS= read -r img; do
            [[ -n "$img" ]] && images+=("$img")
        done < <(extract_images "$content")

        if [[ ${#images[@]} -gt 0 ]]; then
            echo -e "  ${CYAN}Copying images...${RESET}"
            copy_images "$slug" "${images[@]}"
        fi

        # Copy and transform post
        copy_post "$file" "$slug" "$year"
        echo -e "  ${GREEN}Published:${RESET} ${BLOG_DIR}/${year}/${slug}.md"
    done

    echo ""
    echo -e "${GREEN}Successfully processed ${#SELECTED_FILES[@]} post(s)${RESET}"
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "=== Publish Workflow ==="
    echo ""

    # Load configuration
    load_config

    # Discover posts
    discover_posts

    # Check if any posts to publish
    if [[ ${#POST_FILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No posts ready to publish.${RESET}"
        echo ""
        echo "To publish a post, set its status to 'Published' in Obsidian:"
        echo "  status:"
        echo "    - Published"
        echo ""
        exit $EXIT_SUCCESS
    fi

    echo "Found ${GREEN}${#POST_FILES[@]}${RESET} post(s) ready to publish"
    echo ""

    # Interactive selection
    if ! select_posts; then
        echo ""
        echo -e "${YELLOW}No posts selected. Cancelled.${RESET}"
        exit $EXIT_CANCELLED
    fi

    # Validate selection
    if [[ ${#SELECTED_FILES[@]} -eq 0 ]]; then
        echo ""
        echo -e "${YELLOW}No posts selected. Cancelled.${RESET}"
        exit $EXIT_CANCELLED
    fi

    echo ""
    echo -e "${GREEN}Selected ${#SELECTED_FILES[@]} post(s) for publishing${RESET}"

    # Validate selected posts
    validate_selected_posts

    # Process posts: extract images, transform wiki-links, copy to blog
    process_posts

    exit $EXIT_SUCCESS
}

main "$@"
