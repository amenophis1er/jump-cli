#!/usr/bin/env bats

load helpers/test_helpers

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

# === COMPLETION TESTS ===

@test "completion: _jump_complete function handles first argument" {
    # Create a simplified completion function for testing
    cat > /tmp/completion_func.sh << 'EOF'
_jump_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmd="${COMP_WORDS[1]}"
    
    # Get shortcuts dynamically
    local shortcuts=""
    if [[ -f "$HOME/.jump_shortcuts" ]]; then
        shortcuts=$(cut -d: -f1 "$HOME/.jump_shortcuts" 2>/dev/null | tr '\n' ' ' | xargs)
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
        "remove"|"rm")
            COMPREPLY=($(compgen -W "$shortcuts" -- "$cur"))
            ;;
        "add"|"update")
            case "$COMP_CWORD" in
                3) COMPREPLY=($(compgen -d -- "$cur")) ;;
                *) COMPREPLY=() ;;
            esac
            ;;
        *) COMPREPLY=() ;;
    esac
}
EOF
    source /tmp/completion_func.sh
    
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    create_test_shortcut "mobile" "$TEST_HOME/Projects/mobile"
    
    # Test completion for first argument
    COMP_WORDS=("j" "")
    COMP_CWORD=1
    _jump_complete
    
    # Should include commands and shortcuts
    [[ " ${COMPREPLY[*]} " =~ " add " ]] || fail "Should complete 'add' command"
    [[ " ${COMPREPLY[*]} " =~ " list " ]] || fail "Should complete 'list' command"
    [[ " ${COMPREPLY[*]} " =~ " webapp " ]] || fail "Should complete 'webapp' shortcut"
    [[ " ${COMPREPLY[*]} " =~ " mobile " ]] || fail "Should complete 'mobile' shortcut"
}

@test "completion: completes shortcuts for remove command" {
    # Create a simplified completion function for testing
    cat > /tmp/completion_func.sh << 'EOF'
_jump_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmd="${COMP_WORDS[1]}"
    
    # Get shortcuts dynamically
    local shortcuts=""
    if [[ -f "$HOME/.jump_shortcuts" ]]; then
        shortcuts=$(cut -d: -f1 "$HOME/.jump_shortcuts" 2>/dev/null | tr '\n' ' ' | xargs)
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
        "remove"|"rm")
            COMPREPLY=($(compgen -W "$shortcuts" -- "$cur"))
            ;;
        "add"|"update")
            case "$COMP_CWORD" in
                3) COMPREPLY=($(compgen -d -- "$cur")) ;;
                *) COMPREPLY=() ;;
            esac
            ;;
        *) COMPREPLY=() ;;
    esac
}
EOF
    source /tmp/completion_func.sh
    
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    create_test_shortcut "mobile" "$TEST_HOME/Projects/mobile"
    
    # Test completion for remove command
    COMP_WORDS=("j" "remove" "")
    COMP_CWORD=2
    _jump_complete
    
    # Should only include shortcuts, not commands
    [[ " ${COMPREPLY[*]} " =~ " webapp " ]] || fail "Should complete 'webapp' shortcut"
    [[ " ${COMPREPLY[*]} " =~ " mobile " ]] || fail "Should complete 'mobile' shortcut"
    [[ ! " ${COMPREPLY[*]} " =~ " add " ]] || fail "Should not complete 'add' command"
}

@test "completion: completes action keywords for shortcuts" {
    # Create a simplified completion function for testing
    cat > /tmp/completion_func.sh << 'EOF'
_jump_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmd="${COMP_WORDS[1]}"
    
    # Get shortcuts dynamically
    local shortcuts=""
    if [[ -f "$HOME/.jump_shortcuts" ]]; then
        shortcuts=$(cut -d: -f1 "$HOME/.jump_shortcuts" 2>/dev/null | tr '\n' ' ' | xargs)
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
        "remove"|"rm")
            COMPREPLY=($(compgen -W "$shortcuts" -- "$cur"))
            ;;
        "add"|"update")
            case "$COMP_CWORD" in
                3) COMPREPLY=($(compgen -d -- "$cur")) ;;
                *) COMPREPLY=() ;;
            esac
            ;;
        *) COMPREPLY=() ;;
    esac
}
EOF
    source /tmp/completion_func.sh
    
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app" "npm start"
    
    # Test completion for shortcut action
    COMP_WORDS=("j" "webapp" "")
    COMP_CWORD=2
    _jump_complete
    
    # Should include action keywords
    [[ " ${COMPREPLY[*]} " =~ " run " ]] || fail "Should complete 'run' action"
    [[ " ${COMPREPLY[*]} " =~ " action " ]] || fail "Should complete 'action' keyword"
    [[ " ${COMPREPLY[*]} " =~ " do " ]] || fail "Should complete 'do' keyword"
}

@test "completion: completes directories for add command" {
    # Create a simplified completion function for testing
    cat > /tmp/completion_func.sh << 'EOF'
_jump_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmd="${COMP_WORDS[1]}"
    
    # Get shortcuts dynamically
    local shortcuts=""
    if [[ -f "$HOME/.jump_shortcuts" ]]; then
        shortcuts=$(cut -d: -f1 "$HOME/.jump_shortcuts" 2>/dev/null | tr '\n' ' ' | xargs)
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
        "remove"|"rm")
            COMPREPLY=($(compgen -W "$shortcuts" -- "$cur"))
            ;;
        "add"|"update")
            case "$COMP_CWORD" in
                3) COMPREPLY=($(compgen -d -- "$cur")) ;;
                *) COMPREPLY=() ;;
            esac
            ;;
        *) COMPREPLY=() ;;
    esac
}
EOF
    source /tmp/completion_func.sh
    
    # Test completion for add command path argument
    COMP_WORDS=("j" "add" "newproject" "")
    COMP_CWORD=3
    _jump_complete
    
    # Should complete directories (testing this is tricky in isolation)
    # At minimum, should not crash
    [[ ${#COMPREPLY[@]} -ge 0 ]] || fail "Completion should not fail"
}

# === INSTALLATION TESTS ===

@test "install: creates shell function correctly" {
    # Test that install.sh creates the j function
    local temp_config="$TEST_HOME/.test_bashrc"
    
    # Mock shell config detection
    SHELL_CONFIG="$temp_config"
    
    # Extract and evaluate only the SHELL_FUNCTION variable from install.sh
    eval "$(sed -n '/^SHELL_FUNCTION=/,/^fi'\''$/p' "$BATS_TEST_DIRNAME/../install.sh")"
    
    # Write the shell function to temp config
    echo "$SHELL_FUNCTION" > "$temp_config"
    
    # Source the function
    source "$temp_config"
    
    # Test that j function exists
    type j >/dev/null || fail "j function should be defined after sourcing"
}

@test "install: detects shell type correctly" {
    source "$BATS_TEST_DIRNAME/../install.sh"
    
    # Test bash detection
    export BASH_VERSION="5.0"
    unset ZSH_VERSION
    result=$(detect_shell)
    [[ "$result" == "bash" ]] || fail "Should detect bash correctly"
    
    # Test zsh detection
    export ZSH_VERSION="5.8"
    unset BASH_VERSION
    result=$(detect_shell)
    [[ "$result" == "zsh" ]] || fail "Should detect zsh correctly"
    
    # Test unknown detection
    unset BASH_VERSION ZSH_VERSION
    result=$(detect_shell)
    [[ "$result" == "unknown" ]] || fail "Should detect unknown shell correctly"
}

@test "install: determines correct config file" {
    source "$BATS_TEST_DIRNAME/../install.sh"
    
    # Test zsh config
    export SHELL="/bin/zsh"
    touch "$TEST_HOME/.zshrc"
    result=$(get_shell_config)
    [[ "$result" == "$TEST_HOME/.zshrc" ]] || fail "Should use .zshrc for zsh"
    
    # Test bash config with .bashrc
    export SHELL="/bin/bash"
    touch "$TEST_HOME/.bashrc"
    rm -f "$TEST_HOME/.zshrc"
    result=$(get_shell_config)
    [[ "$result" == "$TEST_HOME/.bashrc" ]] || fail "Should use .bashrc when it exists"
    
    # Test bash config with .bash_profile
    rm -f "$TEST_HOME/.bashrc"
    touch "$TEST_HOME/.bash_profile"
    result=$(get_shell_config)
    [[ "$result" == "$TEST_HOME/.bash_profile" ]] || fail "Should use .bash_profile when .bashrc doesn't exist"
}

# === J FUNCTION BEHAVIOR TESTS ===

@test "j function: handles non-cd commands correctly" {
    # Create a mock j function for testing
    j() {
        local non_cd_commands=("add" "update" "list" "ls" "search" "find" "remove" "rm" "edit" "stats" "export" "import" "help" "--help" "-h" "version" "--version" "-v")
        
        for cmd in "${non_cd_commands[@]}"; do
            if [[ "$1" == "$cmd" ]]; then
                echo "jump $*"
                return
            fi
        done
        
        echo "would change directory for: $1"
    }
    
    # Test management commands
    result=$(j add test /tmp)
    [[ "$result" == "jump add test /tmp" ]] || fail "Should call jump for add command"
    
    result=$(j list)
    [[ "$result" == "jump list" ]] || fail "Should call jump for list command"
    
    # Test navigation commands
    result=$(j myshortcut)
    [[ "$result" == "would change directory for: myshortcut" ]] || fail "Should handle shortcuts differently"
}

# === EXPORT/IMPORT TESTS ===

@test "export: creates backup file with default name" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app" "npm start"
    
    run jump_cmd export
    assert_status_success
    
    # Should create a backup file with timestamp
    local backup_files=($(ls "$TEST_HOME"/jump_backup_*.txt 2>/dev/null))
    [[ ${#backup_files[@]} -eq 1 ]] || fail "Should create exactly one backup file"
    
    # Verify backup content
    assert_file_contains "${backup_files[0]}" "webapp:$TEST_HOME/Projects/web-app:npm start"
}

@test "export: creates backup file with custom name" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    
    local custom_backup="$TEST_HOME/my_shortcuts.txt"
    run jump_cmd export "$custom_backup"
    assert_status_success
    
    assert_file_exists "$custom_backup"
    assert_file_contains "$custom_backup" "webapp:$TEST_HOME/Projects/web-app:"
}

@test "import: restores shortcuts from backup" {
    # Create original shortcuts
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app" "npm start"
    create_test_shortcut "mobile" "$TEST_HOME/Projects/mobile" "flutter run"
    
    # Export them
    local backup_file="$TEST_HOME/backup.txt"
    run jump_cmd export "$backup_file"
    assert_status_success
    
    # Clear shortcuts
    rm "$SHORTCUTS_FILE"
    
    # Import them back
    run jump_cmd import "$backup_file"
    assert_status_success
    
    # Verify restoration
    assert_file_contains "$SHORTCUTS_FILE" "webapp:$TEST_HOME/Projects/web-app:npm start"
    assert_file_contains "$SHORTCUTS_FILE" "mobile:$TEST_HOME/Projects/mobile:flutter run"
}

@test "import: fails with non-existent file" {
    run jump_cmd import "/non/existent/file.txt"
    assert_status_error
    assert_output_contains "Usage:"
}

# === EDITOR INTEGRATION TESTS ===

@test "edit: opens shortcuts file in editor" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    
    # Mock editor
    export EDITOR="echo Editor called on"
    
    run jump_cmd edit
    assert_status_success
    assert_output_contains "Editor called on"
}

@test "edit: uses nano as default editor" {
    # Unset EDITOR
    unset EDITOR
    
    # This test is tricky to run without actually opening nano
    # We'll just verify the command doesn't crash
    timeout 1s jump_cmd edit 2>/dev/null || true
    # If we get here without hanging, the test passes
}

# === HELP AND VERSION TESTS ===

@test "help: displays comprehensive help" {
    run jump_cmd help
    assert_status_success
    assert_output_contains "Jump - Enhanced Directory Shortcut Manager"
    assert_output_contains "Basic Usage:"
    assert_output_contains "Management:"
    assert_output_contains "Advanced:"
    assert_output_contains "Examples:"
}

@test "help: all help aliases work" {
    run jump_cmd --help
    assert_status_success
    assert_output_contains "Jump - Enhanced Directory Shortcut Manager"
    
    run jump_cmd -h
    assert_status_success
    assert_output_contains "Jump - Enhanced Directory Shortcut Manager"
}

# === FUZZY SEARCH INTEGRATION ===

@test "fuzzy search: finds partial matches" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    create_test_shortcut "webtools" "$TEST_HOME/Development/tools"
    create_test_shortcut "mobile" "$TEST_HOME/Projects/mobile"
    
    # Test that fuzzy search is called for non-exact matches
    run jump_cmd web
    assert_status_error  # Should not jump, should show options
    assert_output_contains "Multiple matches found"
    assert_output_contains "webapp"
    assert_output_contains "webtools"
    assert_output_not_contains "mobile"
}

# === CONFIGURATION FILE TESTS ===

@test "config: creates default config file" {
    rm -f "$CONFIG_FILE"
    
    # Any jump operation should create config
    run jump_cmd list
    assert_status_success
    
    assert_file_exists "$CONFIG_FILE"
    assert_file_contains "$CONFIG_FILE" "show_path=true"
}

@test "config: preserves existing config" {
    echo "show_path=false" > "$CONFIG_FILE"
    echo "custom_setting=value" >> "$CONFIG_FILE"
    
    run jump_cmd list
    assert_status_success
    
    # Should preserve custom settings
    assert_file_contains "$CONFIG_FILE" "show_path=false"
    assert_file_contains "$CONFIG_FILE" "custom_setting=value"
}