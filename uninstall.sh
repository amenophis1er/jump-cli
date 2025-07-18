#!/bin/bash

# Jump CLI - Uninstall Script
# This script removes Jump CLI and cleans up shell integration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_colored() {
    echo -e "${1}${2}${NC}"
}

print_success() { print_colored "$GREEN" "✓ $1"; }
print_error() { print_colored "$RED" "✗ $1"; }
print_info() { print_colored "$BLUE" "ℹ $1"; }
print_warning() { print_colored "$YELLOW" "⚠ $1"; }

echo -e "${YELLOW}Jump CLI Uninstaller${NC}"
echo ""

# Ask for confirmation
read -p "Are you sure you want to uninstall Jump CLI? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Uninstall cancelled."
    exit 0
fi

# Remove binary
if [[ -f "$HOME/bin/jump" ]]; then
    rm "$HOME/bin/jump"
    print_success "Removed jump binary"
else
    print_warning "Jump binary not found"
fi

# Ask about data files
echo ""
read -p "Remove shortcuts and configuration files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    [[ -f "$HOME/.jump_shortcuts" ]] && rm "$HOME/.jump_shortcuts" && print_success "Removed shortcuts file"
    [[ -f "$HOME/.jump_config" ]] && rm "$HOME/.jump_config" && print_success "Removed config file"
else
    print_info "Keeping shortcuts and configuration files"
fi

# Clean shell configs
for config_file in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [[ -f "$config_file" ]]; then
        # Remove Jump CLI sections
        if grep -q "# Jump CLI" "$config_file"; then
            # Create backup
            cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
            
            # Remove Jump CLI sections
            sed -i.tmp '/# Jump CLI/,/^$/d' "$config_file" 2>/dev/null || true
            rm -f "${config_file}.tmp" 2>/dev/null || true
            
            print_success "Cleaned $config_file"
            
            # Auto-source the cleaned config file if it's the current shell
            current_shell_config=""
            case "$SHELL" in
                */zsh) current_shell_config="$HOME/.zshrc" ;;
                */bash) 
                    if [[ -f "$HOME/.bashrc" ]]; then
                        current_shell_config="$HOME/.bashrc"
                    elif [[ -f "$HOME/.bash_profile" ]]; then
                        current_shell_config="$HOME/.bash_profile"
                    fi
                    ;;
            esac
            
            # Remove j function from current shell session and source cleaned config
            if [[ "$config_file" == "$current_shell_config" ]]; then
                print_info "Removing j function from current shell session..."
                unset -f j 2>/dev/null || true
                print_info "Auto-sourcing $config_file to apply changes..."
                source "$config_file" 2>/dev/null || true
            fi
        fi
    fi
done

echo ""
print_success "Jump CLI has been uninstalled!"
print_info "Changes have been applied to your current shell session."
print_info "Backup files have been created for your shell configurations."
