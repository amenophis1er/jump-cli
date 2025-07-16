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
    local shell_type=$(detect_shell)
    case $shell_type in
        "zsh")
            echo "$HOME/.zshrc"
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

# Copy the jump script
if [[ -f "jump" ]]; then
    cp jump "$BIN_DIR/jump"
    chmod +x "$BIN_DIR/jump"
    print_success "Installed jump script to $BIN_DIR/jump"
else
    print_error "jump script not found in current directory"
    exit 1
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

# Add shell function
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
    
    # For shortcuts, execute the cd command
    local result=$(jump "$@")
    if [[ $result == cd* ]]; then
        eval "$result"
        # Show current directory after jumping
        echo "📁 $(pwd)"
    else
        echo "$result"
    fi
}'

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
