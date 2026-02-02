#!/usr/bin/env bash
# List posts from Obsidian vault with validation status
set -euo pipefail

# Source shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Filter mode (default, all, or published)
FILTER_MODE="unpublished"

# ============================================================================
# Argument Parsing
# ============================================================================

print_usage() {
    echo "Usage: $0 [--all | --published]"
    echo ""
    echo "List blog posts from Obsidian with validation status."
    echo ""
    echo "Options:"
    echo "  --all        Show all posts with Published status"
    echo "  --published  Show only posts already in blog repo"
    echo "  (default)    Show only unpublished/new posts"
    echo ""
    echo "Output:"
    echo "  Table showing title, date, status (ready/invalid), and validation errors"
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                FILTER_MODE="all"
                shift
                ;;
            --published)
                FILTER_MODE="published"
                shift
                ;;
            --help|-h)
                print_usage
                ;;
            *)
                echo "Unknown option: $1" >&2
                print_usage
                ;;
        esac
    done
}

is_published_in_blog() {
    # Check if a post exists in the blog repo
    local slug="$1"
    local pub_date="$2"

    # Extract year from pub_date
    local year="${pub_date:0:4}"

    # Check if file exists in year directory
    local blog_path="${BLOG_DIR}/${year}/${slug}.md"
    if [[ -f "$blog_path" ]]; then
        return 0
    fi

    return 1
}

# ============================================================================
# Post Discovery and Listing
# ============================================================================

list_published_posts() {
    # List posts directly from the blog directory (already published)
    # This mode does NOT require Obsidian vault - scans blog repo directly

    # Find all posts in blog directory
    local found_files=()
    while IFS= read -r -d '' file; do
        found_files+=("$file")
    done < <(find "$BLOG_DIR" -name "*.md" -type f -print0 2>/dev/null)

    if [[ ${#found_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No published posts found in $BLOG_DIR${RESET}"
        exit $EXIT_SUCCESS
    fi

    # Arrays to hold post data
    declare -a titles=()
    declare -a dates=()

    # Process each post
    for file in "${found_files[@]}"; do
        local title
        local pub_date

        # Extract metadata
        title=$(extract_frontmatter_value "$file" "title")
        pub_date=$(extract_frontmatter_value "$file" "pubDatetime")

        # Fallback: use filename as title if not set
        if [[ -z "$title" ]]; then
            title=$(basename "$file" .md)
        fi

        # Store data
        titles+=("$title")
        dates+=("$pub_date")
    done

    # Sort by date descending
    declare -a sort_keys=()
    for i in "${!titles[@]}"; do
        local sort_date="${dates[$i]:-0000-00-00}"
        sort_keys+=("${sort_date}|${i}")
    done

    local sorted_indices=()
    while IFS='|' read -r date idx; do
        sorted_indices+=("$idx")
    done < <(printf '%s\n' "${sort_keys[@]}" | sort -t'|' -k1,1r)

    # Display table header
    echo ""
    printf "%-40s %-12s\n" "TITLE" "DATE"
    printf '%.0s─' {1..54}
    echo ""

    # Display posts
    for idx in "${sorted_indices[@]}"; do
        local title="${titles[$idx]}"
        local date="${dates[$idx]}"

        # Truncate title if too long
        if [[ ${#title} -gt 40 ]]; then
            title="${title:0:37}..."
        fi

        # Format date for display
        local display_date="${date:0:10}"
        if [[ -z "$display_date" || "$display_date" == "null" ]]; then
            display_date="(no date)"
        fi

        printf "%-40s %-12s\n" "$title" "$display_date"
    done

    echo ""
}

list_posts() {
    # For --published mode, scan blog directory directly (no vault needed)
    if [[ "$FILTER_MODE" == "published" ]]; then
        list_published_posts
        return
    fi

    # Discover all posts with draft: false
    local found_files=()

    while IFS= read -r -d '' file; do
        # Check if file contains draft: false
        # Using perl for pattern matching: draft:\s*false
        if perl -0777 -ne 'exit(!/draft:\s*false/i)' "$file" 2>/dev/null; then
            found_files+=("$file")
        fi
    done < <(find "$VAULT_PATH" -name "*.md" -type f -print0 2>/dev/null)

    if [[ ${#found_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No posts found with draft: false.${RESET}"
        echo ""
        echo "To mark a post for publishing, set in frontmatter:"
        echo "  draft: false"
        exit $EXIT_SUCCESS
    fi

    # Arrays to hold post data
    declare -a titles=()
    declare -a dates=()
    declare -a statuses=()
    declare -a error_msgs=()
    declare -a is_published=()

    # Process each post
    for file in "${found_files[@]}"; do
        local title
        local pub_date
        local filename
        local slug
        local validation_errors
        local status
        local published="false"

        # Extract metadata
        filename=$(basename "$file")
        slug=$(slugify "$filename")
        title=$(extract_frontmatter_value "$file" "title")
        pub_date=$(extract_frontmatter_value "$file" "pubDatetime")

        # Fallback: use filename as title if not set
        if [[ -z "$title" ]]; then
            title="${filename%.md}"
        fi

        # Check if already published in blog
        if [[ -n "$pub_date" ]] && is_published_in_blog "$slug" "$pub_date"; then
            published="true"
        fi

        # Validate frontmatter
        if validation_errors=$(validate_frontmatter "$file"); then
            status="ready"
        else
            status="invalid"
        fi

        # Store data
        titles+=("$title")
        dates+=("$pub_date")
        statuses+=("$status")
        error_msgs+=("$validation_errors")
        is_published+=("$published")
    done

    # Filter based on mode
    local filtered_indices=()
    for i in "${!titles[@]}"; do
        case "$FILTER_MODE" in
            all)
                filtered_indices+=("$i")
                ;;
            published)
                if [[ "${is_published[$i]}" == "true" ]]; then
                    filtered_indices+=("$i")
                fi
                ;;
            unpublished)
                if [[ "${is_published[$i]}" == "false" ]]; then
                    filtered_indices+=("$i")
                fi
                ;;
        esac
    done

    # Check if any posts match filter
    if [[ ${#filtered_indices[@]} -eq 0 ]]; then
        case "$FILTER_MODE" in
            published)
                echo -e "${YELLOW}No published posts found.${RESET}"
                ;;
            unpublished)
                echo -e "${YELLOW}No unpublished posts found.${RESET}"
                ;;
            all)
                echo -e "${YELLOW}No posts found.${RESET}"
                ;;
        esac
        exit $EXIT_SUCCESS
    fi

    # Sort: ready status first, then by date descending
    # Create sort keys: "status_priority|date|index"
    # ready=0, invalid=1 (so ready sorts first)
    declare -a sort_keys=()
    for idx in "${filtered_indices[@]}"; do
        local priority
        if [[ "${statuses[$idx]}" == "ready" ]]; then
            priority="0"
        else
            priority="1"
        fi
        local sort_date="${dates[$idx]:-0000-00-00}"
        sort_keys+=("${priority}|${sort_date}|${idx}")
    done

    # Sort by priority (asc) then date (desc)
    local sorted_indices=()
    while IFS='|' read -r priority date idx; do
        sorted_indices+=("$idx")
    done < <(printf '%s\n' "${sort_keys[@]}" | sort -t'|' -k1,1 -k2,2r)

    # Display table header
    echo ""
    printf "%-40s %-12s %-10s\n" "TITLE" "DATE" "STATUS"
    printf '%.0s─' {1..64}
    echo ""

    # Display posts
    for idx in "${sorted_indices[@]}"; do
        local title="${titles[$idx]}"
        local date="${dates[$idx]}"
        local status="${statuses[$idx]}"
        local errors="${error_msgs[$idx]}"

        # Truncate title if too long
        if [[ ${#title} -gt 40 ]]; then
            title="${title:0:37}..."
        fi

        # Format date for display
        local display_date="${date:0:10}"
        if [[ -z "$display_date" || "$display_date" == "null" ]]; then
            display_date="(no date)"
        fi

        # Color status
        local colored_status
        if [[ "$status" == "ready" ]]; then
            colored_status="${GREEN}Ready${RESET}"
        else
            colored_status="${RED}Invalid${RESET}"
        fi

        # Print row (use echo -e for ANSI color support)
        echo -e "$(printf "%-40s %-12s " "$title" "$display_date")$colored_status"

        # Print errors if invalid
        if [[ "$status" == "invalid" && -n "$errors" ]]; then
            while IFS= read -r error; do
                echo -e "  ${YELLOW}→${RESET} $error"
            done <<< "$errors"
        fi
    done

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

    # List posts
    list_posts

    exit $EXIT_SUCCESS
}

main "$@"
