#!/usr/bin/env bats

load helpers/test_helpers

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

# === ADD COMMAND TESTS ===

@test "add: creates shortcut with absolute path" {
    run jump_cmd add webapp "$TEST_HOME/Projects/web-app"
    assert_status_success
    assert_file_exists "$SHORTCUTS_FILE"
    assert_file_contains "$SHORTCUTS_FILE" "webapp:$TEST_HOME/Projects/web-app:"
    assert_output_contains "Shortcut created successfully"
}

@test "add: creates shortcut with relative path (dot)" {
    cd "$TEST_HOME/Projects/web-app"
    run jump_cmd add webapp .
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "webapp:$TEST_HOME/Projects/web-app:"
}

@test "add: creates shortcut with actions" {
    run jump_cmd add webapp "$TEST_HOME/Projects/web-app" "npm start"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "webapp:$TEST_HOME/Projects/web-app:npm start"
    assert_output_contains "Actions:"
    assert_output_contains "npm start"
}

@test "add: creates shortcut with complex actions" {
    run jump_cmd add server "$TEST_HOME/Projects" "cd backend && npm install && npm start"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "server:$TEST_HOME/Projects:cd backend && npm install && npm start"
}

@test "add: fails for non-existent directory" {
    run jump_cmd add nonexistent "/non/existent/path"
    assert_status_error
    assert_output_contains "does not exist"
}

@test "add: fails when shortcut already exists" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    run jump_cmd add webapp "$TEST_HOME/Projects/mobile-app"
    assert_status_error
    assert_output_contains "already exists"
}

@test "add: fails with missing arguments" {
    run jump_cmd add
    assert_status_error
    assert_output_contains "Usage:"
    
    run jump_cmd add webapp
    assert_status_error
    assert_output_contains "Usage:"
}

# === LIST COMMAND TESTS ===

@test "list: shows empty state message" {
    run jump_cmd list
    assert_status_success
    assert_output_contains "No shortcuts configured yet"
    assert_output_contains "Get started:"
}

@test "list: shows single shortcut" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    run jump_cmd list
    assert_status_success
    assert_output_contains "webapp"
    assert_output_contains "Projects/web-app"
    assert_output_contains "(1 total)"
}

@test "list: shows multiple shortcuts with actions" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app" "npm start"
    create_test_shortcut "mobile" "$TEST_HOME/Projects/mobile-app"
    run jump_cmd list
    assert_status_success
    assert_output_contains "webapp"
    assert_output_contains "mobile"
    assert_output_contains "npm start"
    assert_output_contains "(none)"
    assert_output_contains "(2 total)"
}

@test "list: ls alias works" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    run jump_cmd ls
    assert_status_success
    assert_output_contains "webapp"
}

# === REMOVE COMMAND TESTS ===

@test "remove: deletes existing shortcut" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    run jump_cmd remove webapp
    assert_status_success
    assert_output_contains "Removed shortcut 'webapp'"
    assert_file_not_contains "$SHORTCUTS_FILE" "webapp:"
}

@test "remove: rm alias works" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    run jump_cmd rm webapp
    assert_status_success
    assert_output_contains "Removed shortcut 'webapp'"
}

@test "remove: fails for non-existent shortcut" {
    run jump_cmd remove nonexistent
    assert_status_error
    assert_output_contains "not found"
    assert_output_contains "No shortcuts exist to remove."
}

@test "remove: fails with missing argument" {
    run jump_cmd remove
    assert_status_error
    assert_output_contains "Usage:"
}

# === UPDATE COMMAND TESTS ===

@test "update: modifies existing shortcut path" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    run jump_cmd update webapp "$TEST_HOME/Projects/mobile-app"
    assert_status_success
    assert_output_contains "updated successfully"
    assert_file_contains "$SHORTCUTS_FILE" "webapp:$TEST_HOME/Projects/mobile-app:"
    assert_file_not_contains "$SHORTCUTS_FILE" "webapp:$TEST_HOME/Projects/web-app:"
}

@test "update: modifies shortcut with actions" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    run jump_cmd update webapp "$TEST_HOME/Projects/web-app" "npm test"
    assert_status_success
    assert_file_contains "$SHORTCUTS_FILE" "webapp:$TEST_HOME/Projects/web-app:npm test"
}

@test "update: fails for non-existent shortcut" {
    run jump_cmd update nonexistent "$TEST_HOME/Projects"
    assert_status_error
    assert_output_contains "not found"
}

@test "update: fails for non-existent directory" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    run jump_cmd update webapp "/non/existent/path"
    assert_status_error
    assert_output_contains "does not exist"
}

# === SEARCH COMMAND TESTS ===

@test "search: finds matching shortcuts" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app" "npm start"
    create_test_shortcut "mobile" "$TEST_HOME/Projects/mobile-app"
    create_test_shortcut "webtools" "$TEST_HOME/Development/tools"
    
    run jump_cmd search web
    assert_status_success
    assert_output_contains "webapp"
    assert_output_contains "webtools"
    assert_output_not_contains "mobile"
    assert_output_contains "Found 2 matching"
}

@test "search: find alias works" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    run jump_cmd find web
    assert_status_success
    assert_output_contains "webapp"
}

@test "search: shows no results message" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app"
    run jump_cmd search nonexistent
    assert_status_success
    assert_output_contains "No shortcuts found"
    assert_output_contains "Try partial matches"
}

@test "search: fails with missing argument" {
    run jump_cmd search
    assert_status_error
    assert_output_contains "Usage:"
}

# === STATS COMMAND TESTS ===

@test "stats: shows empty state" {
    run jump_cmd stats
    assert_status_success
    assert_output_contains "No shortcuts configured yet"
    assert_output_contains "Get started:"
}

@test "stats: shows statistics for shortcuts" {
    create_test_shortcut "webapp" "$TEST_HOME/Projects/web-app" "npm start"
    create_test_shortcut "mobile" "$TEST_HOME/Projects/mobile-app"
    
    run jump_cmd stats
    assert_status_success
    assert_output_contains "Total shortcuts:"
    assert_output_contains "Shortcuts with actions:"
    assert_output_contains "webapp"
    assert_output_contains "mobile"
}

# === VERSION COMMAND TESTS ===

@test "version: displays version information" {
    run jump_cmd version
    assert_status_success
    assert_output_contains "Jump CLI v1.0.0"
    assert_output_contains "Enhanced Directory Shortcut Manager"
}

@test "version: --version alias works" {
    run jump_cmd --version
    assert_status_success
    assert_output_contains "Jump CLI v1.0.0"
}

@test "version: -v alias works" {
    run jump_cmd -v
    assert_status_success
    assert_output_contains "Jump CLI v1.0.0"
}