#!/bin/bash

# Jump CLI - Enhanced Tab Completion
# Provides intelligent directory discovery and smart completion

# Directory discovery cache file
JUMP_CACHE_FILE="$HOME/.jump_directory_cache"
JUMP_CACHE_MAX_AGE=3600  # 1 hour in seconds
JUMP_MAX_COMPLETIONS=10
JUMP_SEARCH_DEPTH=3
JUMP_COMPLETION_TIMEOUT=2

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

# Score directory match based on pattern matching
score_directory_match() {
    local pattern="$1"
    local dir_name="$2"
    local full_path="$3"
    local score=0
    
    # Convert to lowercase for case-insensitive matching
    local pattern_lower="$(echo "$pattern" | tr '[:upper:]' '[:lower:]')"
    local dir_lower="$(echo "$dir_name" | tr '[:upper:]' '[:lower:]')"
    
    # Exact match: 100 points
    if [[ "$dir_lower" == "$pattern_lower" ]]; then
        score=100
    # Starts with: 80 points
    elif [[ "$dir_lower" =~ ^"$pattern_lower" ]]; then
        score=80
    # Contains: 60 points
    elif [[ "$dir_lower" =~ "$pattern_lower" ]]; then
        score=60
    # Fuzzy match (pattern chars appear in order): 40 points
    elif echo "$dir_lower" | grep -q "$(echo "$pattern_lower" | sed 's/./&.*/g')"; then
        score=40
    else
        return 1  # No match
    fi
    
    # Bonus points for common project locations
    case "$full_path" in
        "$HOME/Projects"*) score=$((score + 10)) ;;
        "$HOME/Code"*) score=$((score + 10)) ;;
        "$HOME/src"*) score=$((score + 8)) ;;
        "$HOME/workspace"*) score=$((score + 8)) ;;
    esac
    
    # Recent access bonus (if file was accessed recently)
    if [[ -d "$full_path" ]] && [[ $(find "$full_path" -maxdepth 0 -mtime -1 2>/dev/null) ]]; then
        score=$((score + 20))
    fi
    
    echo "$score"
}

# Update directory cache in background
update_directory_cache() {
    local temp_cache="$JUMP_CACHE_FILE.tmp"
    
    # Run in background to avoid blocking completion
    (
        {
            timeout "$JUMP_COMPLETION_TIMEOUT" find "${JUMP_SEARCH_PATHS[@]}" \
                -maxdepth "$JUMP_SEARCH_DEPTH" \
                -type d \
                -not -path '*/.*' \
                -not -path '*/node_modules*' \
                -not -path '*/.git*' \
                -not -path '*/vendor*' \
                -not -path '*/target*' \
                -not -path '*/build*' \
                -not -path '*/dist*' \
                2>/dev/null || true
        } > "$temp_cache"
        
        # Only update if we got results
        if [[ -s "$temp_cache" ]]; then
            mv "$temp_cache" "$JUMP_CACHE_FILE"
        else
            rm -f "$temp_cache"
        fi
    ) &
}

# Check if cache needs updating
should_update_cache() {
    [[ ! -f "$JUMP_CACHE_FILE" ]] || [[ $(($(date +%s) - $(stat -f %m "$JUMP_CACHE_FILE" 2>/dev/null || echo 0))) -gt $JUMP_CACHE_MAX_AGE ]]
}

# Find smart directory suggestions
find_smart_directories() {
    local pattern="$1"
    local results=()
    local scored_results=()
    
    # Update cache if needed (non-blocking)
    if should_update_cache; then
        update_directory_cache
    fi
    
    # Search cached directories if cache exists
    if [[ -f "$JUMP_CACHE_FILE" ]]; then
        while IFS= read -r dir_path; do
            [[ -z "$dir_path" ]] && continue
            [[ ! -d "$dir_path" ]] && continue
            
            local dir_name=$(basename "$dir_path")
            local score
            score=$(score_directory_match "$pattern" "$dir_name" "$dir_path" 2>/dev/null)
            
            if [[ $? -eq 0 ]] && [[ $score -gt 0 ]]; then
                scored_results+=("$score:$dir_name:$dir_path")
            fi
        done < "$JUMP_CACHE_FILE"
    fi
    
    # Sort by score (descending) and extract directory names
    printf '%s\n' "${scored_results[@]}" | \
        sort -t: -k1,1nr | \
        head -n "$JUMP_MAX_COMPLETIONS" | \
        cut -d: -f2
}

# Enhanced completion function
_jump_enhanced_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmd="${COMP_WORDS[1]}"
    local suggestions=()
    
    # Get existing shortcuts
    local shortcuts=""
    if [[ -f "$HOME/.jump_shortcuts" ]]; then
        shortcuts=$(cut -d: -f1 "$HOME/.jump_shortcuts" 2>/dev/null | tr '\n' ' ' | xargs)
    fi
    
    # If completing first argument
    if [[ $COMP_CWORD -eq 1 ]]; then
        local commands="add update remove rm list ls search find edit stats export import help version"
        
        # Priority 1: Commands and existing shortcuts
        local combined="$commands $shortcuts"
        local command_matches=($(compgen -W "$combined" -- "$cur"))
        
        # Priority 2: Smart directory discovery if no exact matches
        if [[ ${#command_matches[@]} -eq 0 ]] && [[ -n "$cur" ]]; then
            local dir_suggestions=()
            while IFS= read -r line; do
                [[ -n "$line" ]] && dir_suggestions+=("$line")
            done < <(find_smart_directories "$cur")
            suggestions=("${dir_suggestions[@]}")
        else
            suggestions=("${command_matches[@]}")
        fi
        
        COMPREPLY=("${suggestions[@]}")
        return
    fi
    
    # If completing second argument and first is a shortcut
    if [[ $COMP_CWORD -eq 2 && " $shortcuts " =~ " $cmd " ]]; then
        COMPREPLY=($(compgen -W "run action do" -- "$cur"))
        return
    fi
    
    # Command-specific completion
    case "$cmd" in
        "remove"|"rm")
            COMPREPLY=($(compgen -W "$shortcuts" -- "$cur"))
            ;;
        "add"|"update")
            case "$COMP_CWORD" in
                3) 
                    # For path completion, also suggest smart directories
                    local dir_completions=($(compgen -d -- "$cur"))
                    if [[ ${#dir_completions[@]} -eq 0 ]] && [[ -n "$cur" ]]; then
                        local smart_dirs=()
                        while IFS= read -r line; do
                            [[ -n "$line" ]] && smart_dirs+=("$line")
                        done < <(find_smart_directories "$cur")
                        # Convert directory names back to full paths for these suggestions
                        local smart_paths=()
                        for dir_name in "${smart_dirs[@]}"; do
                            if [[ -f "$JUMP_CACHE_FILE" ]]; then
                                local full_path=$(grep "/$dir_name$" "$JUMP_CACHE_FILE" | head -1)
                                [[ -n "$full_path" ]] && smart_paths+=("$full_path")
                            fi
                        done
                        COMPREPLY=("${smart_paths[@]}")
                    else
                        COMPREPLY=("${dir_completions[@]}")
                    fi
                    ;;
                *) COMPREPLY=() ;;
            esac
            ;;
        *) COMPREPLY=() ;;
    esac
}

# Register the enhanced completion function
complete -F _jump_enhanced_completion j

# Also register for the jump command if it exists
if command -v jump >/dev/null 2>&1; then
    complete -F _jump_enhanced_completion jump
fi