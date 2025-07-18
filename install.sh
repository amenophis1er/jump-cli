#!/bin/bash

# Jump CLI - Easy Installation Script
# This script installs Jump CLI and sets up the shell integration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_colored() {
    echo -e "${1}${2}${NC}"
}

print_success() { print_colored "$GREEN" "✓ $1"; }
print_error() { print_colored "$RED" "✗ $1"; }
print_info() { print_colored "$BLUE" "ℹ $1"; }
print_warning() { print_colored "$YELLOW" "⚠ $1"; }

# Detect shell
detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# Get shell config file
get_shell_config() {
    # Check actual user shell (not current execution shell)
    local user_shell=$(basename "$SHELL")
    
    case $user_shell in
        "zsh")
            if [[ -f "$HOME/.zshrc" ]]; then
                echo "$HOME/.zshrc"
            else
                # Create .zshrc if it doesn't exist for zsh users
                touch "$HOME/.zshrc"
                echo "$HOME/.zshrc"
            fi
            ;;
        "bash")
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

echo -e "${CYAN}"
cat << "EOF"
     ██╗██╗   ██╗███╗   ███╗██████╗      ██████╗██╗     ██╗
     ██║██║   ██║████╗ ████║██╔══██╗    ██╔════╝██║     ██║
     ██║██║   ██║██╔████╔██║██████╔╝    ██║     ██║     ██║
██   ██║██║   ██║██║╚██╔╝██║██╔═══╝     ██║     ██║     ██║
╚█████╔╝╚██████╔╝██║ ╚═╝ ██║██║         ╚██████╗███████╗██║
 ╚════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝          ╚═════╝╚══════╝╚═╝
                                                            
Enhanced Directory Shortcut Manager
EOF
echo -e "${NC}"

print_info "Starting Jump CLI installation..."

# Create bin directory if it doesn't exist
BIN_DIR="$HOME/bin"
if [[ ! -d "$BIN_DIR" ]]; then
    mkdir -p "$BIN_DIR"
    print_success "Created $BIN_DIR directory"
fi

# Download jump script from latest release or use local if available
if [[ -f "jump" ]]; then
    # Local installation (for development)
    cp jump "$BIN_DIR/jump"
    chmod +x "$BIN_DIR/jump"
    print_success "Installed jump script from local directory to $BIN_DIR/jump"
    
    # Also install enhanced completion script if available
    if [[ -f "enhanced_completion.sh" ]]; then
        cp "enhanced_completion.sh" "$BIN_DIR/"
        print_success "Installed enhanced completion script"
    fi
    
    # Install cache manager script if available  
    if [[ -f "cache_manager.sh" ]]; then
        cp "cache_manager.sh" "$BIN_DIR/"
        chmod +x "$BIN_DIR/cache_manager.sh"
        print_success "Installed cache manager script"
    fi
else
    # Download from GitHub release
    print_info "Downloading Jump CLI from latest release..."
    
    # Get the latest release download URL
    LATEST_URL="https://api.github.com/repos/amenophis1er/jump-cli/releases/latest"
    DOWNLOAD_URL="https://github.com/amenophis1er/jump-cli/releases/latest/download/jump"
    
    # Download the jump script
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$DOWNLOAD_URL" -o "$BIN_DIR/jump" || {
            print_error "Failed to download jump script. Falling back to main branch..."
            curl -fsSL "https://raw.githubusercontent.com/amenophis1er/jump-cli/main/jump" -o "$BIN_DIR/jump" || {
                print_error "Failed to download jump script from main branch"
                exit 1
            }
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$DOWNLOAD_URL" -O "$BIN_DIR/jump" || {
            print_error "Failed to download jump script. Falling back to main branch..."
            wget -q "https://raw.githubusercontent.com/amenophis1er/jump-cli/main/jump" -O "$BIN_DIR/jump" || {
                print_error "Failed to download jump script from main branch"
                exit 1
            }
        }
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    chmod +x "$BIN_DIR/jump"
    print_success "Downloaded and installed jump script to $BIN_DIR/jump"
    
    # Also install enhanced completion script if available
    if [[ -f "enhanced_completion.sh" ]]; then
        cp "enhanced_completion.sh" "$BIN_DIR/"
        print_success "Installed enhanced completion script"
    fi
fi

# Get shell config file
SHELL_CONFIG=$(get_shell_config)
print_info "Detected shell config: $SHELL_CONFIG"

# Check if PATH already includes ~/bin
if ! echo "$PATH" | grep -q "$HOME/bin"; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Jump CLI - Add ~/bin to PATH" >> "$SHELL_CONFIG"
    echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_CONFIG"
    print_success "Added ~/bin to PATH in $SHELL_CONFIG"
fi

# Add shell function and completion
SHELL_FUNCTION='
# Jump CLI - Shell Integration
j() {
    # Commands that don'\''t change directory
    local non_cd_commands=("add" "update" "list" "ls" "search" "find" "remove" "rm" "edit" "stats" "export" "import" "help" "--help" "-h" "version" "--version" "-v")
    
    # Check if it'\''s a non-cd command
    for cmd in "${non_cd_commands[@]}"; do
        if [[ "$1" == "$cmd" ]]; then
            jump "$@"
            return
        fi
    done
    
    # Handle empty command
    if [[ -z "$1" ]]; then
        jump "$@"
        return
    fi
    
    # For shortcuts, execute the cd command with enhanced output
    # Check if user wants verbose output
    if [[ "$2" == "--verbose" || "$2" == "-v" ]]; then
        local result=$(jump --format-jump-verbose "$1")
    else
        local result=$(jump --format-jump "$1")
    fi
    
    if [[ $result == cd* ]]; then
        eval "$result"
    else
        echo "$result"
    fi
}

# Jump CLI - Auto-completion
_jump_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local cmd="${COMP_WORDS[1]}"
    
    # Get shortcuts dynamically
    local shortcuts=""
    if [[ -f "$HOME/.jump_shortcuts" ]]; then
        shortcuts=$(cut -d: -f1 "$HOME/.jump_shortcuts" 2>/dev/null | tr '\''\n'\'' '\'' '\'' | xargs)
    fi
    
    # If first argument, complete with commands + shortcuts
    if [[ $COMP_CWORD -eq 1 ]]; then
        local commands="add update remove rm list ls search find edit stats export import help version"
        COMPREPLY=($(compgen -W "$commands $shortcuts" -- "$cur"))
        return
    fi
    
    # If second argument and first is a shortcut, complete with action keywords
    if [[ $COMP_CWORD -eq 2 && " $shortcuts " =~ " $cmd " ]]; then
        COMPREPLY=($(compgen -W "run action do" -- "$cur"))
        return
    fi
    
    # Command-specific completion
    case "$cmd" in
        "add"|"update")
            case "$COMP_CWORD" in
                2) # Shortcut name - no completion
                   COMPREPLY=()
                   ;;
                3) # Directory path
                   COMPREPLY=($(compgen -d -- "$cur"))
                   ;;
                *) # Actions - no completion
                   COMPREPLY=()
                   ;;
            esac
            ;;
        "remove"|"rm")
            # Complete with existing shortcuts
            COMPREPLY=($(compgen -W "$shortcuts" -- "$cur"))
            ;;
        "search"|"find")
            # Complete with existing shortcuts for search hints
            if [[ $COMP_CWORD -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$shortcuts" -- "$cur"))
            fi
            ;;
        "import")
            # Complete with files
            COMPREPLY=($(compgen -f -- "$cur"))
            ;;
        "export")
            # Complete with .txt files and allow custom naming
            COMPREPLY=($(compgen -f -X '\''!*.txt'\'' -- "$cur"))
            if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
                COMPREPLY=($(compgen -W "backup.txt jump_backup.txt" -- "$cur"))
            fi
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

# Register completion for bash
if [[ -n "$BASH_VERSION" ]]; then
    complete -F _jump_complete j
fi

# Zsh completion support
if [[ -n "$ZSH_VERSION" ]]; then
    # Enable zsh completion system
    autoload -U compinit
    compinit
    
    # Define zsh completion function
    _jump_zsh_complete() {
        local context curcontext="$curcontext" state line
        local shortcuts=""
        
        # Get shortcuts dynamically
        if [[ -f "$HOME/.jump_shortcuts" ]]; then
            shortcuts=(${(f)"$(cut -d: -f1 "$HOME/.jump_shortcuts" 2>/dev/null)"})
        fi
        
        _arguments -C \
            '\''1: :->first_arg'\'' \
            '\''2: :->second_arg'\'' \
            '\''*: :->other_args'\'' && return 0
        
        case $state in
            first_arg)
                local commands=(add update remove rm list ls search find edit stats export import help version)
                _alternative \
                    '\''commands:commands:($commands)'\'' \
                    '\''shortcuts:shortcuts:($shortcuts)'\''
                ;;
            second_arg)
                case $words[2] in
                    add|update)
                        _message '\''shortcut name'\''
                        ;;
                    remove|rm)
                        _alternative '\''shortcuts:shortcuts:($shortcuts)'\''
                        ;;
                    search|find)
                        _alternative '\''shortcuts:shortcuts:($shortcuts)'\''
                        ;;
                    import)
                        _files
                        ;;
                    export)
                        _files -g '\''*.txt'\''
                        ;;
                    *)
                        if [[ " ${shortcuts[@]} " =~ " ${words[2]} " ]]; then
                            _alternative '\''actions:actions:(run action do)'\''
                        fi
                        ;;
                esac
                ;;
            other_args)
                case $words[2] in
                    add|update)
                        if [[ $CURRENT -eq 3 ]]; then
                            _directories
                        else
                            _message '\''action commands'\''
                        fi
                        ;;
                esac
                ;;
        esac
    }
    
    # Register zsh completion
    compdef _jump_zsh_complete j
fi

# Enhanced completion with smart directory discovery
# Source enhanced completion if available
if [[ -f "$HOME/bin/enhanced_completion.sh" ]]; then
    source "$HOME/bin/enhanced_completion.sh"
fi'

# Check if function already exists
if ! grep -q "# Jump CLI - Shell Integration" "$SHELL_CONFIG" 2>/dev/null; then
    echo "$SHELL_FUNCTION" >> "$SHELL_CONFIG"
    print_success "Added shell integration function to $SHELL_CONFIG"
else
    print_warning "Shell integration already exists in $SHELL_CONFIG"
fi

echo ""
print_success "Jump CLI installation completed!"
echo ""
print_info "To start using Jump CLI:"
echo "  1. Restart your terminal or run: source $SHELL_CONFIG"
echo "  2. Add your first shortcut: j add myproject ~/path/to/project"
echo "  3. Jump to it: j myproject"
echo ""
print_info "Available commands:"
echo "  j add <name> <path> [actions]  - Add shortcut"
echo "  j list                         - List all shortcuts"
echo "  j <shortcut>                   - Jump to directory"
echo "  j help                         - Show full help"
echo ""
print_info "Repository: https://github.com/amenophis1er/jump-cli"
