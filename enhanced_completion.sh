#!/bin/bash

# Jump CLI - Enhanced Completion Script
# This script replaces the standard completion with intelligent directory discovery

# Configuration
JUMP_CACHE_FILE="$HOME/.jump_directory_cache"
JUMP_CACHE_MAX_AGE=3600
JUMP_MAX_COMPLETIONS=10
JUMP_SEARCH_DEPTH=3
JUMP_COMPLETION_TIMEOUT=2

# Search paths for smart directory discovery
JUMP_SEARCH_PATHS=(
    "$HOME/Projects"
    "$HOME/Code" 
    "$HOME/src"
    "$HOME/workspace"
    "$HOME/Documents"
    "$HOME/Development"
    "$HOME/dev"
)

# Score directory match for intelligent ranking
score_directory_match() {
    local pattern="$1"
    local dir_name="$2"
    local full_path="$3"
    local score=0
    
    local pattern_lower="$(echo "$pattern" | tr '[:upper:]' '[:lower:]')"
    local dir_lower="$(echo "$dir_name" | tr '[:upper:]' '[:lower:]')"
    
    if [[ "$dir_lower" == "$pattern_lower" ]]; then
        score=100
    elif [[ "$dir_lower" =~ ^"$pattern_lower" ]]; then
        score=80
    elif [[ "$dir_lower" =~ "$pattern_lower" ]]; then
        score=60
    elif echo "$dir_lower" | grep -q "$(echo "$pattern_lower" | sed 's/./&.*/g')"; then
        score=40
    else
        return 1
    fi
    
    case "$full_path" in
        "$HOME/Projects"*) score=$((score + 10)) ;;
        "$HOME/Code"*) score=$((score + 10)) ;;
        "$HOME/src"*) score=$((score + 8)) ;;
        "$HOME/workspace"*) score=$((score + 8)) ;;
    esac
    
    if [[ -d "$full_path" ]] && [[ $(find "$full_path" -maxdepth 0 -mtime -1 2>/dev/null) ]]; then
        score=$((score + 20))
    fi
    
    echo "$score"
}

# Update directory cache in background
update_directory_cache() {
    local temp_cache="$JUMP_CACHE_FILE.tmp"
    
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
    local scored_results=()
    
    # Return empty for empty pattern
    [[ -z "$pattern" ]] && return 0
    
    if should_update_cache; then
        update_directory_cache
    fi
    
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
    
    printf '%s\n' "${scored_results[@]}" | \
        sort -t: -k1,1nr | \
        head -n "$JUMP_MAX_COMPLETIONS" | \
        cut -d: -f2
}

# Enhanced completion function
_jump_enhanced_complete() {
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
        
        # Priority 2: Smart directory discovery if no exact matches and pattern provided
        if [[ ${#command_matches[@]} -eq 0 ]] && [[ -n "$cur" ]] && [[ ${#cur} -ge 2 ]]; then
            local dir_suggestions
            # Use read loop instead of mapfile for compatibility
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
                    # For path completion, suggest both local directories and smart discoveries
                    local dir_completions=($(compgen -d -- "$cur"))
                    if [[ ${#dir_completions[@]} -eq 0 ]] && [[ -n "$cur" ]] && [[ ${#cur} -ge 2 ]]; then
                        local smart_dirs=()
                        # Use read loop instead of mapfile for compatibility
                        while IFS= read -r line; do
                            [[ -n "$line" ]] && smart_dirs+=("$line")
                        done < <(find_smart_directories "$cur")
                        # Convert directory names back to full paths
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
        "search"|"find")
            if [[ $COMP_CWORD -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$shortcuts" -- "$cur"))
            fi
            ;;
        "import")
            COMPREPLY=($(compgen -f -- "$cur"))
            ;;
        "export")
            COMPREPLY=($(compgen -f -X '!*.txt' -- "$cur"))
            if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
                COMPREPLY=($(compgen -W "backup.txt jump_backup.txt" -- "$cur"))
            fi
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

# Register the enhanced completion function for bash
if [[ -n "$BASH_VERSION" ]]; then
    complete -F _jump_enhanced_complete j
    if command -v jump >/dev/null 2>&1; then
        complete -F _jump_enhanced_complete jump
    fi
fi

# Enhanced Zsh completion
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -U compinit
    compinit -u 2>/dev/null

    _jump_enhanced_zsh_complete() {
        local context curcontext="$curcontext" state line
        local shortcuts=()
        
        # Get shortcuts dynamically
        if [[ -f "$HOME/.jump_shortcuts" ]]; then
            shortcuts=(${(f)"$(cut -d: -f1 "$HOME/.jump_shortcuts" 2>/dev/null)"})
        fi
        
        _arguments -C \
            '1: :->first_arg' \
            '2: :->second_arg' \
            '*: :->other_args' && return 0
        
        case $state in
            first_arg)
                local commands=(add update remove rm list ls search find edit stats export import help version)
                local combined=($commands $shortcuts)
                
                # Try smart directory discovery if no matches
                if ! _alternative \
                    'commands:commands:($commands)' \
                    'shortcuts:shortcuts:($shortcuts)'; then
                    if [[ -n "${words[2]}" ]] && [[ ${#words[2]} -ge 2 ]]; then
                        local smart_dirs=($(find_smart_directories "${words[2]}"))
                        if [[ ${#smart_dirs[@]} -gt 0 ]]; then
                            _alternative 'smart-dirs:smart directories:($smart_dirs)'
                        fi
                    fi
                fi
                ;;
            second_arg)
                case $words[2] in
                    add|update)
                        _message 'shortcut name'
                        ;;
                    remove|rm)
                        _alternative 'shortcuts:shortcuts:($shortcuts)'
                        ;;
                    search|find)
                        _alternative 'shortcuts:shortcuts:($shortcuts)'
                        ;;
                    import)
                        _files
                        ;;
                    export)
                        _files -g '*.txt'
                        ;;
                    *)
                        if [[ " ${shortcuts[@]} " =~ " ${words[2]} " ]]; then
                            _alternative 'actions:actions:(run action do)'
                        fi
                        ;;
                esac
                ;;
            other_args)
                case $words[2] in
                    add|update)
                        if [[ $CURRENT -eq 3 ]]; then
                            # Directory completion with smart discovery fallback
                            if ! _directories; then
                                if [[ -n "${words[4]}" ]] && [[ ${#words[4]} -ge 2 ]]; then
                                    local smart_paths=()
                                    local smart_dirs=($(find_smart_directories "${words[4]}"))
                                    for dir_name in $smart_dirs; do
                                        if [[ -f "$JUMP_CACHE_FILE" ]]; then
                                            local full_path=$(grep "/$dir_name$" "$JUMP_CACHE_FILE" | head -1)
                                            [[ -n "$full_path" ]] && smart_paths+=("$full_path")
                                        fi
                                    done
                                    if [[ ${#smart_paths[@]} -gt 0 ]]; then
                                        _alternative "smart-paths:smart paths:($smart_paths)"
                                    fi
                                fi
                            fi
                        else
                            _message 'action commands'
                        fi
                        ;;
                esac
                ;;
        esac
    }
    
    # Register zsh completion
    compdef _jump_enhanced_zsh_complete j
    if command -v jump >/dev/null 2>&1; then
        compdef _jump_enhanced_zsh_complete jump
    fi
fi