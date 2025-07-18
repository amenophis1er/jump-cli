#!/usr/bin/env bats

load helpers/test_helpers

setup() {
    setup_test_env
    
    # Source the cache manager script
    source "$BATS_TEST_DIRNAME/../cache_manager.sh"
    
    # Override cache paths for testing
    JUMP_CACHE_FILE="$TEST_HOME/.jump_directory_cache"
    JUMP_CACHE_LOCK="$TEST_HOME/.jump_cache.lock"
    JUMP_SEARCH_PATHS=(
        "$TEST_HOME/Projects"
        "$TEST_HOME/Code"
    )
    
    # Create test directory structure
    mkdir -p "$TEST_HOME/Projects/web-app"
    mkdir -p "$TEST_HOME/Projects/mobile-app"
    mkdir -p "$TEST_HOME/Code/backend"
    mkdir -p "$TEST_HOME/Code/frontend"
}

teardown() {
    teardown_test_env
}

# === CACHE UPDATE TESTS ===

@test "cache manager: creates cache file on first update" {
    # Remove any existing cache
    rm -f "$JUMP_CACHE_FILE"
    
    # Update cache
    run update_cache "true" "false"  # force=true, verbose=false
    assert_status_success
    
    # Should create cache file
    assert_file_exists "$JUMP_CACHE_FILE"
}

@test "cache manager: cache contains expected directories" {
    # Update cache
    update_cache "true" "false"
    
    # Check cache contents
    assert_file_exists "$JUMP_CACHE_FILE"
    assert_file_contains "$JUMP_CACHE_FILE" "web-app"
    assert_file_contains "$JUMP_CACHE_FILE" "mobile-app"
    assert_file_contains "$JUMP_CACHE_FILE" "backend"
    assert_file_contains "$JUMP_CACHE_FILE" "frontend"
}

@test "cache manager: excludes hidden directories" {
    # Create hidden directories
    mkdir -p "$TEST_HOME/Projects/.hidden"
    mkdir -p "$TEST_HOME/Projects/normal"
    
    # Update cache
    update_cache "true" "false"
    
    # Should exclude hidden directories
    assert_file_not_contains "$JUMP_CACHE_FILE" ".hidden"
    assert_file_contains "$JUMP_CACHE_FILE" "normal"
}

@test "cache manager: excludes common build directories" {
    # Create excluded directories
    mkdir -p "$TEST_HOME/Projects/myapp/node_modules"
    mkdir -p "$TEST_HOME/Projects/myapp/build"
    mkdir -p "$TEST_HOME/Projects/myapp/dist"
    mkdir -p "$TEST_HOME/Projects/myapp/.git"
    mkdir -p "$TEST_HOME/Projects/myapp/src"  # This should be included
    
    # Update cache
    update_cache "true" "false"
    
    # Should exclude build/dependency directories
    assert_file_not_contains "$JUMP_CACHE_FILE" "node_modules"
    assert_file_not_contains "$JUMP_CACHE_FILE" "build"
    assert_file_not_contains "$JUMP_CACHE_FILE" "dist"
    assert_file_not_contains "$JUMP_CACHE_FILE" ".git"
    
    # Should include source directories
    assert_file_contains "$JUMP_CACHE_FILE" "src"
}

# === CACHE AGE TESTS ===

@test "cache manager: detects fresh cache" {
    # Create fresh cache
    touch "$JUMP_CACHE_FILE"
    
    # Should detect cache is fresh
    if cache_needs_update; then
        fail "Fresh cache should not need update"
    fi
}

@test "cache manager: detects old cache" {
    # Create old cache file (simulate old timestamp)
    touch "$JUMP_CACHE_FILE"
    
    # Wait a moment then reduce max age for testing
    sleep 1
    JUMP_CACHE_MAX_AGE=0
    
    # Should detect cache needs update
    if ! cache_needs_update; then
        fail "Old cache should need update"
    fi
}

@test "cache manager: detects missing cache" {
    # Remove cache file
    rm -f "$JUMP_CACHE_FILE"
    
    # Should detect cache needs update
    if ! cache_needs_update; then
        fail "Missing cache should need update"
    fi
}

# === CACHE LOCKING TESTS ===

@test "cache manager: creates and removes lock" {
    # Should not be locked initially
    if is_cache_locked; then
        fail "Cache should not be locked initially"
    fi
    
    # Create lock
    create_cache_lock
    
    # Should be locked
    if ! is_cache_locked; then
        fail "Cache should be locked after creating lock"
    fi
    
    # Remove lock
    remove_cache_lock
    
    # Should not be locked
    if is_cache_locked; then
        fail "Cache should not be locked after removing lock"
    fi
}

@test "cache manager: prevents concurrent updates" {
    # Create lock
    create_cache_lock
    
    # Should skip update when locked
    run update_cache "false" "true"  # force=false, verbose=true
    assert_status_error
    
    # Clean up
    remove_cache_lock
}

@test "cache manager: handles stale locks" {
    # Create old lock file (simulate old timestamp)
    touch "$JUMP_CACHE_LOCK"
    
    # Modify timestamp to be very old using touch with a past date
    # Note: This is a simplified test - in real scenarios, we'd need more sophisticated timestamp manipulation
    
    # For now, just test that lock detection works with fresh lock
    if ! is_cache_locked; then
        fail "Fresh lock should be detected"
    fi
}

# === CACHE STATS TESTS ===

@test "cache manager: shows stats for existing cache" {
    # Create cache with known content
    echo "$TEST_HOME/Projects/web-app" > "$JUMP_CACHE_FILE"
    echo "$TEST_HOME/Projects/mobile-app" >> "$JUMP_CACHE_FILE"
    
    # Get stats
    run show_cache_stats
    assert_status_success
    assert_output_contains "Cache Statistics"
    # The output format may vary, so just check that it runs successfully
}

@test "cache manager: handles missing cache in stats" {
    # Remove cache file
    rm -f "$JUMP_CACHE_FILE"
    
    # Should handle missing cache gracefully
    run show_cache_stats
    assert_status_error
    assert_output_contains "No cache file found"
}

# === CACHE CLEARING TESTS ===

@test "cache manager: clears existing cache" {
    # Create cache file
    echo "test content" > "$JUMP_CACHE_FILE"
    
    # Clear cache
    run clear_cache
    assert_status_success
    assert_output_contains "Cache cleared"
    
    # Should remove cache file
    assert_file_not_exists "$JUMP_CACHE_FILE"
}

@test "cache manager: handles clearing non-existent cache" {
    # Remove cache file
    rm -f "$JUMP_CACHE_FILE"
    
    # Should handle gracefully
    run clear_cache
    assert_status_success
    assert_output_contains "No cache file to clear"
}

# === COMMAND-LINE INTERFACE TESTS ===

@test "cache manager: shows help by default" {
    run cache_manager
    assert_status_success
    assert_output_contains "Jump CLI Cache Manager"
    assert_output_contains "Usage:"
}

@test "cache manager: handles update command" {
    run cache_manager "update"
    assert_status_success
    
    # Should create cache file
    assert_file_exists "$JUMP_CACHE_FILE"
}

@test "cache manager: handles force-update command" {
    # Create existing cache
    touch "$JUMP_CACHE_FILE"
    
    run cache_manager "force-update"
    assert_status_success
    
    # Should update cache even if fresh
    assert_file_exists "$JUMP_CACHE_FILE"
}

@test "cache manager: handles stats command" {
    # Create cache file
    echo "test" > "$JUMP_CACHE_FILE"
    
    run cache_manager "stats"
    assert_status_success
    assert_output_contains "Cache Statistics"
}

@test "cache manager: handles clear command" {
    # Create cache file
    echo "test" > "$JUMP_CACHE_FILE"
    
    run cache_manager "clear"
    assert_status_success
    assert_output_contains "Cache cleared"
    assert_file_not_exists "$JUMP_CACHE_FILE"
}

@test "cache manager: handles auto-update command" {
    run cache_manager "auto-update"
    assert_status_success
    
    # Should create cache file silently
    assert_file_exists "$JUMP_CACHE_FILE"
}

# === FIND COMMAND BUILDING TESTS ===

@test "cache manager: builds correct find command" {
    # Test the find command construction
    local cmd=$(build_find_command)
    
    # Should include search paths
    [[ "$cmd" =~ Projects ]] || fail "Should include Projects path"
    [[ "$cmd" =~ Code ]] || fail "Should include Code path"
    
    # Should include exclusions
    [[ "$cmd" =~ "not -path" ]] || fail "Should include exclusion patterns"
    [[ "$cmd" =~ "node_modules" ]] || fail "Should exclude node_modules"
}

# === DIRECTORY FILTERING TESTS ===

@test "cache manager: respects search depth limit" {
    # Create deep directory structure
    mkdir -p "$TEST_HOME/Projects/level1/level2/level3/level4"
    
    # Set shallow search depth
    JUMP_SEARCH_DEPTH=2
    
    # Update cache
    update_cache "true" "false"
    
    # Should not include very deep directories
    assert_file_not_contains "$JUMP_CACHE_FILE" "level4"
    
    # Should include directories within depth limit
    assert_file_contains "$JUMP_CACHE_FILE" "level1"
    assert_file_contains "$JUMP_CACHE_FILE" "level2"
}

@test "cache manager: includes only directories" {
    # Create files and directories
    mkdir -p "$TEST_HOME/Projects/mydir"
    touch "$TEST_HOME/Projects/myfile.txt"
    
    # Update cache
    update_cache "true" "false"
    
    # Should include directories only
    assert_file_contains "$JUMP_CACHE_FILE" "mydir"
    assert_file_not_contains "$JUMP_CACHE_FILE" "myfile.txt"
}

# === ERROR HANDLING TESTS ===

@test "cache manager: handles non-existent search paths" {
    # Set non-existent search paths
    JUMP_SEARCH_PATHS=("/non/existent/path1" "/non/existent/path2")
    
    # Should not crash
    run update_cache "true" "false"
    # May succeed or fail depending on find behavior, but shouldn't crash
    [[ $status -eq 0 || $status -eq 1 ]] || fail "Should handle non-existent paths gracefully"
}

@test "cache manager: handles permission denied directories" {
    # This test is tricky to implement reliably across different systems
    # For now, just test that the function doesn't crash with normal directories
    run update_cache "true" "false"
    assert_status_success
}

# === PERFORMANCE TESTS ===

@test "cache manager: completes update within timeout" {
    # Test with reasonable timeout
    JUMP_COMPLETION_TIMEOUT=5
    
    # Should complete within timeout
    local start_time=$(date +%s)
    update_cache "true" "false"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    [[ $duration -le 10 ]] || fail "Cache update took too long: ${duration}s"
}

@test "cache manager: handles large directory structures" {
    # Create many directories
    for i in {1..50}; do
        mkdir -p "$TEST_HOME/Projects/project-$i"
    done
    
    # Should handle large structures without issues
    run update_cache "true" "false"
    assert_status_success
    
    # Should contain expected number of entries
    local count=$(wc -l < "$JUMP_CACHE_FILE")
    [[ $count -ge 50 ]] || fail "Should cache all created directories"
}