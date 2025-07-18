#!/usr/bin/env bats

load helpers/test_helpers

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

# === COMPLETE WORKFLOW TESTS ===

@test "workflow: complete project setup workflow" {
    # Create additional test directories
    mkdir -p "$TEST_HOME/Projects/web-app/backend"
    mkdir -p "$TEST_HOME/Projects/web-app/docs"
    
    # Add multiple related shortcuts
    run jump_cmd add frontend "$TEST_HOME/Projects/web-app" "npm start"
    assert_status_success
    
    run jump_cmd add backend "$TEST_HOME/Projects/web-app/backend" "python app.py"
    assert_status_success
    
    run jump_cmd add docs "$TEST_HOME/Projects/web-app/docs" "mkdocs serve"
    assert_status_success
    
    # Verify all shortcuts exist
    run jump_cmd list
    assert_status_success
    assert_output_contains "frontend"
    assert_output_contains "backend"
    assert_output_contains "docs"
    assert_output_contains "(3 total)"
    
    # Search for related shortcuts
    run jump_cmd search web
    assert_status_success
    assert_output_contains "Found 3 matching"
    
    # Update one of them
    run jump_cmd update frontend "$TEST_HOME/Projects/web-app" "npm run dev"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "frontend:.*:npm run dev"
    
    # Remove one
    run jump_cmd remove docs
    assert_status_success
    
    # Verify final state
    run jump_cmd list
    assert_status_success
    assert_output_contains "(2 total)"
    assert_output_not_contains "docs"
}

@test "workflow: backup and restore shortcuts" {
    # Create some shortcuts
    run jump_cmd add webapp "$TEST_HOME/Projects/web-app" "npm start"
    run jump_cmd add mobile "$TEST_HOME/Projects/mobile-app" "flutter run"
    
    # Export shortcuts
    local backup_file="$TEST_HOME/backup.txt"
    run jump_cmd export "$backup_file"
    assert_status_success
    assert_file_exists "$backup_file"
    assert_file_contains "$backup_file" "webapp:"
    assert_file_contains "$backup_file" "mobile:"
    
    # Clear shortcuts
    rm "$SHORTCUTS_FILE"
    run jump_cmd list
    assert_output_contains "No shortcuts configured"
    
    # Import shortcuts back
    run jump_cmd import "$backup_file"
    assert_status_success
    
    # Verify restoration
    run jump_cmd list
    assert_status_success
    assert_output_contains "webapp"
    assert_output_contains "mobile"
    assert_output_contains "(2 total)"
}

@test "workflow: development project lifecycle" {
    # Create test directory
    mkdir -p "$TEST_HOME/Projects/myproject"
    
    # Initial project setup
    run jump_cmd add myproject "$TEST_HOME/Projects/myproject"
    assert_status_success
    
    # Add development action
    run jump_cmd update myproject "$TEST_HOME/Projects/myproject" "code ."
    assert_status_success
    
    # Verify action was added
    assert_file_contains "$SHORTCUTS_FILE" "myproject:.*:code ."
    
    # Test project statistics
    run jump_cmd stats
    assert_status_success
    assert_output_contains "Total shortcuts:"
    assert_output_contains "Shortcuts with actions:"
    
    # Create additional directories and add more project shortcuts
    mkdir -p "$TEST_HOME/Projects/myproject/tests"
    mkdir -p "$TEST_HOME/Projects/myproject/docs"
    run jump_cmd add myproject-test "$TEST_HOME/Projects/myproject/tests" "pytest"
    run jump_cmd add myproject-docs "$TEST_HOME/Projects/myproject/docs" "mkdocs serve"
    
    # Search for project-related shortcuts
    run jump_cmd search myproject
    assert_status_success
    assert_output_contains "Found 3 matching"
    
    # Clean up project shortcuts
    run jump_cmd remove myproject-test
    run jump_cmd remove myproject-docs
    run jump_cmd remove myproject
    
    # Verify cleanup
    run jump_cmd list
    assert_output_contains "No shortcuts configured"
}

# === JUMP FUNCTIONALITY TESTS ===

@test "jump: formats output correctly for shortcut with actions" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app" "npm start"
    
    run jump_cmd --format-jump webapp
    assert_status_success
    assert_output_contains "webapp"
    assert_output_contains "cd \""
}

@test "jump: formats output correctly for shortcut without actions" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    
    run jump_cmd --format-jump webapp
    assert_status_success
    assert_output_contains "webapp"
    assert_output_contains "cd \""
}

@test "jump: verbose format shows detailed information" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app" "npm start"
    
    run jump_cmd --format-jump-verbose webapp
    assert_status_success
    assert_output_contains "Jumped to:"
    assert_output_contains "webapp"
    assert_output_contains "Projects/web-app"
    assert_output_contains "Available actions:"
    assert_output_contains "npm start"
    assert_output_contains "cd \""
}

@test "jump: handles non-existent shortcut gracefully" {
    run jump_cmd nonexistent
    assert_status_error
    assert_output_contains "Shortcut \"nonexistent\" not found"
    # The output shows "Suggestions:" instead of "Available shortcuts:"
    assert_output_contains "Suggestions:"
}

@test "jump: fuzzy search works when exact match not found" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    create_test_shortcut "webtools" "$TEST_HOME/Development/tools"
    
    run jump_cmd web
    assert_status_error  # Should show fuzzy matches, not jump
    assert_output_contains "Multiple matches found"
    assert_output_contains "webapp"
    assert_output_contains "webtools"
}

# === ERROR RECOVERY TESTS ===

@test "error recovery: handles corrupted shortcuts file gracefully" {
    # Create a corrupted file
    echo "invalid line without colons" > "$SHORTCUTS_FILE"
    echo "only:one:colon" >> "$SHORTCUTS_FILE"
    echo "proper:format:$TEST_HOME/Projects:" >> "$SHORTCUTS_FILE"
    
    # All operations should still work
    run jump_cmd list
    assert_status_success
    
    run jump_cmd add newshortcut "$TEST_HOME/temp"
    assert_status_success
    
    # Should have added the new shortcut
    assert_file_contains "$SHORTCUTS_FILE" "newshortcut:$TEST_HOME/temp:"
}

@test "error recovery: recreates missing config file" {
    rm -f "$CONFIG_FILE"
    
    run jump_cmd list
    assert_status_success
    
    # Config file should be recreated
    assert_file_exists "$CONFIG_FILE"
    assert_file_contains "$CONFIG_FILE" "show_path=true"
}

# === PERFORMANCE TESTS ===

@test "performance: handles large number of shortcuts efficiently" {
    # Create 50 shortcuts (reasonable performance test)
    for i in {1..50}; do
        create_test_shortcut "shortcut$i" "$TEST_HOME/Projects/project$i" "echo $i"
    done
    
    # List should complete quickly
    run jump_cmd list
    assert_status_success
    assert_output_contains "(50 total)"
    
    # Search should complete quickly
    run jump_cmd search shortcut
    assert_status_success
    assert_output_contains "Found 5 matching"
    
    # Stats should complete quickly
    run jump_cmd stats
    assert_status_success
    assert_output_contains "Total shortcuts:"
}

# === OUTPUT FORMATTING INTEGRATION ===

@test "formatting: all commands produce colored output" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app" "npm start"
    
    # Test that color codes are present
    run jump_cmd list
    assert_status_success
    has_colors || fail "List command should produce colored output"
    
    mkdir -p "$TEST_HOME/Projects/mobile"
    run jump_cmd add mobile "$TEST_HOME/Projects/mobile"
    assert_status_success  
    has_colors || fail "Add command should produce colored output"
    
    run jump_cmd search web
    assert_status_success
    has_colors || fail "Search command should produce colored output"
    
    run jump_cmd stats
    assert_status_success
    has_colors || fail "Stats command should produce colored output"
}

@test "formatting: error messages are properly formatted" {
    run jump_cmd nonexistent
    assert_status_error
    has_colors || fail "Error messages should be colored"
    assert_output_contains "Jump CLI - Shortcut Not Found"
    
    run jump_cmd remove nonexistent
    assert_status_error
    has_colors || fail "Remove error should be colored"
    assert_output_contains "Jump CLI - Remove Shortcut"
}

# === CROSS-COMMAND INTEGRATION ===

@test "integration: commands work together seamlessly" {
    # Start with empty state
    run jump_cmd stats
    assert_output_contains "No shortcuts configured"
    
    # Add shortcuts and verify stats update
    run jump_cmd add webapp "$TEST_HOME/Projects/web-app" "npm start"
    run jump_cmd add mobile "$TEST_HOME/Projects/mobile-app"
    
    run jump_cmd stats
    assert_output_contains "Total shortcuts:"
    assert_output_contains "Shortcuts with actions:"
    
    # Search and verify results
    run jump_cmd search app
    assert_output_contains "Found 2 matching"
    
    # Update and verify changes
    mkdir -p "$TEST_HOME/Projects/mobile-app"
    run jump_cmd update mobile "$TEST_HOME/Projects/mobile-app" "flutter run"
    
    run jump_cmd stats
    assert_output_contains "Shortcuts with actions:"
    
    # Remove and verify cleanup
    run jump_cmd remove webapp
    
    run jump_cmd stats
    assert_output_contains "Total shortcuts:"
    assert_output_contains "Shortcuts with actions:"
    
    # Final verification
    run jump_cmd list
    assert_output_contains "mobile"
    assert_output_not_contains "webapp"
}