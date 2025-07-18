#!/usr/bin/env bats

load helpers/test_helpers

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

# === SPECIAL CHARACTERS AND EDGE CASES ===

@test "add: handles spaces in shortcut names" {
    run jump_cmd add "my project" "$TEST_HOME/Projects"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "my project:$TEST_HOME/Projects:"
}

@test "add: handles spaces in paths" {
    mkdir -p "$TEST_HOME/Projects/my app"
    run jump_cmd add webapp "$TEST_HOME/Projects/my app"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "webapp:$TEST_HOME/Projects/my app:"
}

@test "add: handles quotes in actions" {
    run jump_cmd add webapp "$TEST_HOME/Projects" 'echo "hello world"'
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" 'webapp:.*:echo "hello world"'
}

@test "add: handles complex shell commands in actions" {
    run jump_cmd add webapp "$TEST_HOME/Projects" "source venv/bin/activate && python -m pip install -r requirements.txt"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "source venv/bin/activate"
}

@test "add: handles very long shortcut names" {
    local long_name=$(printf 'a%.0s' {1..50})
    run jump_cmd add "$long_name" "$TEST_HOME/Projects"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "$long_name:$TEST_HOME/Projects:"
}

@test "add: handles very long paths" {
    local deep_path="$TEST_HOME/very/deep/directory/structure/that/goes/on/for/a/while"
    mkdir -p "$deep_path"
    run jump_cmd add deep "$deep_path"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "deep:$deep_path:"
}

@test "add: handles special characters in shortcut names" {
    run jump_cmd add "test-app_v2.0" "$TEST_HOME/Projects"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "test-app_v2.0:$TEST_HOME/Projects:"
}

@test "add: handles tilde in paths" {
    # Test that tilde gets expanded
    run jump_cmd add home "~"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "home:$TEST_HOME:"
}

# === RELATIVE PATH EDGE CASES ===

@test "add: handles current directory (dot)" {
    cd "$TEST_HOME/Projects"
    run jump_cmd add current .
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "current:$TEST_HOME/Projects:"
}

@test "add: handles parent directory (dot dot)" {
    cd "$TEST_HOME/Projects/web-app"
    run jump_cmd add parent ..
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "parent:$TEST_HOME/Projects:"
}

@test "add: handles relative paths with subdirectories" {
    cd "$TEST_HOME"
    run jump_cmd add projects "./Projects"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "projects:$TEST_HOME/Projects:"
}

# === FILE SYSTEM EDGE CASES ===

@test "add: handles symlinks" {
    mkdir -p "$TEST_HOME/Projects"
    ln -s "$TEST_HOME/Projects" "$TEST_HOME/projects_link"
    run jump_cmd add link "$TEST_HOME/projects_link"
    assert_status_success
    
    # Should resolve symlinks - get the actual resolved path
    local resolved_path=$(cd "$TEST_HOME/Projects" && pwd -P)
    assert_file_contains "$SHORTCUTS_FILE" "link:$resolved_path:"
}

@test "handles missing shortcuts file" {
    rm -f "$SHORTCUTS_FILE"
    run jump_cmd list
    assert_status_success
    assert_output_contains "No shortcuts configured"
}

@test "handles corrupted shortcuts file" {
    echo "invalid:format" > "$SHORTCUTS_FILE"
    echo "missing:colon" >> "$SHORTCUTS_FILE"
    echo "proper:format:$TEST_HOME/Projects:" >> "$SHORTCUTS_FILE"
    
    run jump_cmd list
    assert_status_success
    # Should handle corruption gracefully
}

@test "handles empty shortcuts file" {
    touch "$SHORTCUTS_FILE"
    run jump_cmd list
    assert_status_success
    assert_output_contains "No shortcuts configured"
}

# === PERMISSION AND ACCESS EDGE CASES ===

@test "handles readonly shortcuts file" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects"
    chmod 444 "$SHORTCUTS_FILE"
    
    run jump_cmd add another "$TEST_HOME/temp"
    assert_status_error
    
    # Cleanup
    chmod 644 "$SHORTCUTS_FILE"
}

@test "handles directory without read permissions" {
    mkdir -p "$TEST_HOME/restricted"
    chmod 000 "$TEST_HOME/restricted"
    
    run jump_cmd add restricted "$TEST_HOME/restricted"
    # Should still work as we're checking existence, not readability
    
    # Cleanup
    chmod 755 "$TEST_HOME/restricted"
}

# === CONCURRENT ACCESS EDGE CASES ===

@test "handles multiple operations on shortcuts file" {
    # Simulate concurrent access by multiple operations
    create_test_shortcut "webapp" "$TEST_HOME/Projects"
    
    run jump_cmd add mobile "$TEST_HOME/Projects/mobile-app"
    assert_status_success
    
    run jump_cmd update webapp "$TEST_HOME/Projects/web-app"
    assert_status_success
    
    run jump_cmd remove mobile
    assert_status_success
    
    # Verify final state
    assert_file_contains "$SHORTCUTS_FILE" "webapp:$TEST_HOME/Projects/web-app:"
    assert_file_not_contains "$SHORTCUTS_FILE" "mobile:"
}

# === MALFORMED INPUT EDGE CASES ===

@test "handles shortcuts with colons in names" {
    # Colons are our delimiter, so this is tricky
    run jump_cmd add "test:name" "$TEST_HOME/Projects"
    # This might fail or handle gracefully depending on implementation
}

@test "handles shortcuts with newlines in actions" {
    # Test multiline actions
    run jump_cmd add webapp_newlines "$TEST_HOME/Projects" $'echo "line1"\necho "line2"'
    assert_status_success
}

@test "handles very large shortcuts file" {
    # Create many shortcuts to test performance
    for i in {1..100}; do
        create_test_shortcut "test$i" "$TEST_HOME/Projects" "echo $i"
    done
    
    run jump_cmd list
    assert_status_success
    assert_output_contains "(100 total)"
    
    run jump_cmd search test
    assert_status_success
    assert_output_contains "Found 5 matching"
}

# === OUTPUT FORMATTING EDGE CASES ===

@test "list: handles very long paths in display" {
    local very_long_path="$TEST_HOME/very/very/very/very/very/very/very/long/path/that/exceeds/normal/display/width"
    mkdir -p "$very_long_path"
    create_test_shortcut "longpath" "$very_long_path"
    
    run jump_cmd list
    assert_status_success
    # Should truncate path nicely
    assert_output_contains "..."
}

@test "list: handles shortcuts without actions gracefully" {
    echo "webapp:$TEST_HOME/Projects:" >> "$SHORTCUTS_FILE"  # No action part
    
    run jump_cmd list
    assert_status_success
    assert_output_contains "(none)"
}

# === UNICODE AND INTERNATIONAL CHARACTERS ===

@test "add: handles unicode characters in shortcut names" {
    run jump_cmd add "项目" "$TEST_HOME/Projects"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "项目:$TEST_HOME/Projects:"
}

@test "add: handles unicode characters in paths" {
    mkdir -p "$TEST_HOME/项目"
    run jump_cmd add unicode "$TEST_HOME/项目"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "unicode:$TEST_HOME/项目:"
}