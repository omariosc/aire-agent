#!/usr/bin/env bats

SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../scripts" && pwd)"
REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

@test "sync.sh exists and is executable" {
    [ -x "$SCRIPTS_DIR/sync.sh" ]
}

@test "sync.sh --help shows usage" {
    run "$SCRIPTS_DIR/sync.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "sync.sh skips if recently synced" {
    # Set last_sync to now
    date +%s > "$REPO_DIR/.last_sync"
    run "$SCRIPTS_DIR/sync.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"synced"* ]]
}

@test "sync.sh --force overrides recent sync" {
    date +%s > "$REPO_DIR/.last_sync"
    run "$SCRIPTS_DIR/sync.sh" --force
    # Will attempt to clone -- may fail without network but should try
    # Just check it doesn't say "already synced"
    [[ "$output" != *"Use --force"* ]]
}
