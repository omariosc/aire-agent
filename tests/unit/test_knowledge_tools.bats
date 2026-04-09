#!/usr/bin/env bats

TOOLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../tools" && pwd)"
REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

@test "search-docs.sh finds content in knowledge files" {
    run "$TOOLS_DIR/search-docs.sh" "L40S"
    [ "$status" -eq 0 ]
    [[ "$output" == *"L40S"* ]]
}

@test "search-docs.sh returns empty for nonsense query" {
    run "$TOOLS_DIR/search-docs.sh" "zzzznonexistenttermzzzz"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "list-modules.sh shows modules" {
    run "$TOOLS_DIR/list-modules.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"cuda"* ]]
}

@test "system-info.sh shows hardware specs" {
    run "$TOOLS_DIR/system-info.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"GPU"* ]]
    [[ "$output" == *"L40S"* ]]
}

@test "doctor.sh runs without crashing" {
    run "$TOOLS_DIR/doctor.sh"
    # May report issues but should not crash
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "update.sh exists and is executable" {
    [ -x "$TOOLS_DIR/update.sh" ]
}

@test "check-quota.sh exists and is executable" {
    [ -x "$TOOLS_DIR/check-quota.sh" ]
}

@test "node-availability.sh exists and is executable" {
    [ -x "$TOOLS_DIR/node-availability.sh" ]
}

@test "search-docs.sh rejects missing query" {
    run "$TOOLS_DIR/search-docs.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "system-info.sh --json returns valid JSON" {
    run "$TOOLS_DIR/system-info.sh" --json
    [ "$status" -eq 0 ]
    [[ "$output" == *"\"system\""* ]]
}
