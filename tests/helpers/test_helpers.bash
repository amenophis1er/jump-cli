#!/bin/bash
# Test helpers for Jump CLI tests

# Resolve path using same logic as jump script
resolve_path() {
    local path="$1"
    if [[ -d "$path" ]]; then
        cd "$path" && pwd -P
    else
        echo "$path"
    fi
}

# Setup test environment
setup_test_env() {
    export TEST_HOME="/tmp/jump_test_$$"
    export JUMP_TEST_DIR="$TEST_HOME"
    mkdir -p "$TEST_HOME"
    
    # Resolve TEST_HOME to actual path (handles /tmp -> /private/tmp on macOS)
    export TEST_HOME=$(resolve_path "$TEST_HOME")
    
    # Override home directory for testing
    export HOME="$TEST_HOME"
    export SHORTCUTS_FILE="$TEST_HOME/.jump_shortcuts"
    export CONFIG_FILE="$TEST_HOME/.jump_config"
    
    # Create test directories
    mkdir -p "$TEST_HOME/Projects/web-app"
    mkdir -p "$TEST_HOME/Projects/mobile-app"
    mkdir -p "$TEST_HOME/Documents/Work"
    mkdir -p "$TEST_HOME/Development/tools"
    mkdir -p "$TEST_HOME/temp"
}

# Cleanup test environment
teardown_test_env() {
    if [[ -n "$TEST_HOME" && "$TEST_HOME" == "/tmp/jump_test_"* ]]; then
        rm -rf "$TEST_HOME"
    fi
    unset TEST_HOME JUMP_TEST_DIR HOME SHORTCUTS_FILE CONFIG_FILE
}

# Assertion helpers
assert_file_exists() {
    [[ -f "$1" ]] || fail "File $1 does not exist"
}

assert_file_not_exists() {
    [[ ! -f "$1" ]] || fail "File $1 should not exist"
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    assert_file_exists "$file"
    grep -q "$pattern" "$file" || fail "File $file does not contain pattern: $pattern"
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    if [[ -f "$file" ]]; then
        ! grep -q "$pattern" "$file" || fail "File $file should not contain pattern: $pattern"
    fi
}

assert_output_contains() {
    local expected="$1"
    [[ "$output" =~ $expected ]] || fail "Output does not contain: $expected\nActual output: $output"
}

assert_output_not_contains() {
    local not_expected="$1"
    [[ ! "$output" =~ $not_expected ]] || fail "Output should not contain: $not_expected\nActual output: $output"
}

assert_status_success() {
    [[ "$status" -eq 0 ]] || fail "Command failed with status $status\nOutput: $output"
}

assert_status_error() {
    [[ "$status" -ne 0 ]] || fail "Command should have failed but succeeded\nOutput: $output"
}

# Test data helpers
create_test_shortcut() {
    local name="$1"
    local path="$2"
    local actions="${3:-}"
    echo "$name:$path:$actions" >> "$SHORTCUTS_FILE"
}

get_shortcuts_count() {
    if [[ -f "$SHORTCUTS_FILE" ]]; then
        wc -l < "$SHORTCUTS_FILE" | xargs
    else
        echo "0"
    fi
}

# Jump CLI wrapper for testing
jump_cmd() {
    # Use absolute path to jump script
    "$BATS_TEST_DIRNAME/../jump" "$@"
}

# Strip ANSI color codes for testing
strip_colors() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# Helper to test color output
has_colors() {
    [[ "$output" =~ \[.*m ]]
}

# Mock editor for testing
mock_editor() {
    export EDITOR="echo 'mock editor called on'"
}

fail() {
    echo "$@" >&2
    return 1
}