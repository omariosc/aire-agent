#!/usr/bin/env bats

BIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../bin" &>/dev/null && pwd)"
CLI="$BIN_DIR/aire-agent"

@test "aire-agent exists and is executable" {
    [ -x "$CLI" ]
}

@test "aire-agent with no args shows help" {
    run "$CLI"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]] || [[ "$output" == *"usage"* ]]
}

@test "aire-agent --help shows help" {
    run "$CLI" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]] || [[ "$output" == *"usage"* ]]
}

@test "aire-agent --version shows version" {
    run "$CLI" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+ ]]
}

@test "aire-agent routes 'info' to system-info" {
    run "$CLI" info
    [ "$status" -eq 0 ]
    [[ "$output" == *"AIRE"* ]]
}

@test "aire-agent routes 'modules' to list-modules" {
    run "$CLI" modules
    [ "$status" -eq 0 ]
    [[ "$output" == *"cuda"* ]]
}

@test "aire-agent routes 'search' to search-docs" {
    run "$CLI" search "L40S"
    [ "$status" -eq 0 ]
    [[ "$output" == *"L40S"* ]]
}

@test "aire-agent routes 'validate' correctly" {
    tmp=$(mktemp)
    echo -e '#!/bin/bash\n#SBATCH --time=01:00:00' > "$tmp"
    run "$CLI" validate "$tmp"
    [ "$status" -eq 0 ]
    rm "$tmp"
}

@test "aire-agent rejects unknown commands" {
    run "$CLI" nonexistent_command_xyz
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown"* ]] || [[ "$output" == *"unknown"* ]]
}

@test "aire-agent routes 'doctor' correctly" {
    run "$CLI" doctor
    # doctor may pass or fail depending on env, but should not crash with unknown command
    [[ "$output" == *"aire-agent"* ]] || [[ "$output" == *"PASS"* ]] || [[ "$output" == *"FAIL"* ]] || [[ "$output" == *"WARN"* ]]
}
