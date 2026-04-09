#!/usr/bin/env bats

TOOLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../tools" && pwd)"

setup() {
    export AIRE_AGENT_DIR=$(mktemp -d)
    mkdir -p "$AIRE_AGENT_DIR/experiments"
}

teardown() {
    rm -rf "$AIRE_AGENT_DIR"
}

@test "log-experiment.sh exists and is executable" {
    [ -x "$TOOLS_DIR/log-experiment.sh" ]
}

@test "query-experiments.sh exists and is executable" {
    [ -x "$TOOLS_DIR/query-experiments.sh" ]
}

@test "setup-wandb.sh exists and is executable" {
    [ -x "$TOOLS_DIR/setup-wandb.sh" ]
}

@test "log-experiment.sh rejects missing --name" {
    run "$TOOLS_DIR/log-experiment.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"--name"* ]] || [[ "$output" == *"Usage"* ]]
}

@test "log-experiment.sh creates valid JSON log entry" {
    run "$TOOLS_DIR/log-experiment.sh" --name "test_run" --metrics '{"loss": 0.5}' --params '{"lr": 0.001}'
    [ "$status" -eq 0 ]
    # Check the log file was created
    log_file="$AIRE_AGENT_DIR/experiments/experiments.jsonl"
    [ -f "$log_file" ]
    # Verify JSON is valid using python3
    python3 -c "import json; json.loads(open('$log_file').readline())"
}

@test "query-experiments.sh shows logged experiments" {
    "$TOOLS_DIR/log-experiment.sh" --name "test_query" --metrics '{"loss": 0.3}'
    run "$TOOLS_DIR/query-experiments.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"test_query"* ]]
}

@test "query-experiments.sh handles no experiments" {
    rm -f "$AIRE_AGENT_DIR/experiments/experiments.jsonl"
    run "$TOOLS_DIR/query-experiments.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No experiments"* ]]
}

@test "log-experiment.sh accepts --help" {
    run "$TOOLS_DIR/log-experiment.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}
