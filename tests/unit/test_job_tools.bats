#!/usr/bin/env bats

TOOLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../tools" && pwd)"

@test "submit-job.sh exists and is executable" {
    [ -x "$TOOLS_DIR/submit-job.sh" ]
}

@test "check-queue.sh exists and is executable" {
    [ -x "$TOOLS_DIR/check-queue.sh" ]
}

@test "cancel-job.sh exists and is executable" {
    [ -x "$TOOLS_DIR/cancel-job.sh" ]
}

@test "job-status.sh exists and is executable" {
    [ -x "$TOOLS_DIR/job-status.sh" ]
}

@test "job-efficiency.sh exists and is executable" {
    [ -x "$TOOLS_DIR/job-efficiency.sh" ]
}

@test "submit-job.sh rejects missing script argument" {
    run "$TOOLS_DIR/submit-job.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "submit-job.sh rejects nonexistent script" {
    run "$TOOLS_DIR/submit-job.sh" "/nonexistent/script.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "cancel-job.sh rejects missing job ID" {
    run "$TOOLS_DIR/cancel-job.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "job-status.sh rejects missing job ID" {
    run "$TOOLS_DIR/job-status.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "job-efficiency.sh rejects missing job ID" {
    run "$TOOLS_DIR/job-efficiency.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "check-queue.sh accepts --help" {
    run "$TOOLS_DIR/check-queue.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}
