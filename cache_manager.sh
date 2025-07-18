#!/bin/bash

# Jump CLI - Cache Manager
# Manages directory discovery cache for performance optimization

JUMP_CACHE_FILE="$HOME/.jump_directory_cache"
JUMP_CACHE_LOCK="$HOME/.jump_cache.lock"
JUMP_CACHE_MAX_AGE=3600  # 1 hour
JUMP_SEARCH_DEPTH=3

# Common project directories to search
JUMP_SEARCH_PATHS=(
    "$HOME/Projects"
    "$HOME/Code" 
    "$HOME/src"
    "$HOME/workspace"
    "$HOME/Documents"
    "$HOME/Development"
    "$HOME/dev"
)

# Excluded patterns to speed up search
JUMP_EXCLUDE_PATTERNS=(
    "node_modules"
    ".git"
    ".svn"
    ".hg"
    "vendor"
    "target"
    "build"
    "dist"
    "__pycache__"
    ".pytest_cache"
    ".mypy_cache"
    ".tox"
    "venv"
    "env"
    ".env"
)

# Print colored output
print_info() {
    echo -e "\033[0;34mℹ $1\033[0m"
}

print_success() {
    echo -e "\033[0;32m✓ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠ $1\033[0m"
}

print_error() {
    echo -e "\033[0;31m✗ $1\033[0m"
}

# Cross-platform stat function for modification time
get_file_mtime() {
    local file="$1"
    if stat -f %m "$file" >/dev/null 2>&1; then
        # macOS/BSD
        stat -f %m "$file" 2>/dev/null || echo 0
    else
        # Linux/GNU
        stat -c %Y "$file" 2>/dev/null || echo 0
    fi
}

# Check if another cache update is running
is_cache_locked() {
    [[ -f "$JUMP_CACHE_LOCK" ]] && [[ $(($(date +%s) - $(get_file_mtime "$JUMP_CACHE_LOCK"))) -lt 300 ]]
}

# Create cache lock
create_cache_lock() {
    touch "$JUMP_CACHE_LOCK"
}

# Remove cache lock
remove_cache_lock() {
    rm -f "$JUMP_CACHE_LOCK"
}

# Get cache age in seconds
get_cache_age() {
    if [[ -f "$JUMP_CACHE_FILE" ]]; then
        echo $(($(date +%s) - $(get_file_mtime "$JUMP_CACHE_FILE")))
    else
        echo 999999  # Very old if doesn't exist
    fi
}

# Check if cache needs updating
cache_needs_update() {
    local age=$(get_cache_age)
    [[ $age -gt $JUMP_CACHE_MAX_AGE ]]
}

# Build find command with exclusions
build_find_command() {
    local cmd="find"
    
    # Add search paths
    for path in "${JUMP_SEARCH_PATHS[@]}"; do
        [[ -d "$path" ]] && cmd="$cmd \"$path\""
    done
    
    # Add constraints
    cmd="$cmd -maxdepth $JUMP_SEARCH_DEPTH -type d"
    
    # Add exclusions
    for pattern in "${JUMP_EXCLUDE_PATTERNS[@]}"; do
        cmd="$cmd -not -path '*/$pattern*'"
    done
    
    # Add hidden directory exclusion
    cmd="$cmd -not -path '*/.*'"
    
    echo "$cmd 2>/dev/null"
}

# Update directory cache
update_cache() {
    local force="${1:-false}"
    local verbose="${2:-false}"
    
    # Check if update is needed
    if [[ "$force" != "true" ]] && ! cache_needs_update; then
        [[ "$verbose" == "true" ]] && print_info "Cache is up to date (age: $(get_cache_age)s)"
        return 0
    fi
    
    # Check if another update is running
    if is_cache_locked; then
        [[ "$verbose" == "true" ]] && print_warning "Cache update already in progress"
        return 1
    fi
    
    [[ "$verbose" == "true" ]] && print_info "Updating directory cache..."
    
    # Create lock
    create_cache_lock
    
    # Ensure cleanup on exit
    trap 'remove_cache_lock' EXIT INT TERM
    
    local temp_cache="$JUMP_CACHE_FILE.tmp"
    local start_time=$(date +%s)
    
    # Build and execute find command
    local find_cmd=$(build_find_command)
    eval "$find_cmd" > "$temp_cache"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local count=$(wc -l < "$temp_cache" 2>/dev/null || echo 0)
    
    # Only update if we got results
    if [[ -s "$temp_cache" ]]; then
        mv "$temp_cache" "$JUMP_CACHE_FILE"
        [[ "$verbose" == "true" ]] && print_success "Cache updated: $count directories in ${duration}s"
    else
        rm -f "$temp_cache"
        [[ "$verbose" == "true" ]] && print_error "Cache update failed: no directories found"
        remove_cache_lock
        return 1
    fi
    
    remove_cache_lock
    return 0
}

# Show cache statistics
show_cache_stats() {
    if [[ ! -f "$JUMP_CACHE_FILE" ]]; then
        print_warning "No cache file found"
        return 1
    fi
    
    local age=$(get_cache_age)
    local count=$(wc -l < "$JUMP_CACHE_FILE" 2>/dev/null || echo 0)
    local size=$(ls -lh "$JUMP_CACHE_FILE" 2>/dev/null | awk '{print $5}' || echo "unknown")
    local age_human
    
    if [[ $age -lt 60 ]]; then
        age_human="${age}s"
    elif [[ $age -lt 3600 ]]; then
        age_human="$((age / 60))m"
    else
        age_human="$((age / 3600))h"
    fi
    
    echo "Cache Statistics:"
    echo "  File: $JUMP_CACHE_FILE"
    echo "  Age: $age_human"
    echo "  Directories: $count"
    echo "  Size: $size"
    echo "  Status: $(cache_needs_update && echo "needs update" || echo "up to date")"
}

# Clear cache
clear_cache() {
    if [[ -f "$JUMP_CACHE_FILE" ]]; then
        rm -f "$JUMP_CACHE_FILE"
        print_success "Cache cleared"
    else
        print_warning "No cache file to clear"
    fi
    remove_cache_lock
}

# Main cache manager function
cache_manager() {
    case "${1:-help}" in
        "update")
            update_cache "${2:-false}" "true"
            ;;
        "force-update")
            update_cache "true" "true"
            ;;
        "stats"|"status")
            show_cache_stats
            ;;
        "clear")
            clear_cache
            ;;
        "auto-update")
            # Silent auto-update for background use
            update_cache "false" "false"
            ;;
        "help"|*)
            echo "Jump CLI Cache Manager"
            echo ""
            echo "Usage: cache_manager <command>"
            echo ""
            echo "Commands:"
            echo "  stats        Show cache statistics"
            echo "  update       Update cache if needed"
            echo "  force-update Force cache update"
            echo "  clear        Clear cache"
            echo "  auto-update  Silent update for background use"
            echo "  help         Show this help (default)"
            ;;
    esac
}

# Run cache manager if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cache_manager "$@"
fi