#!/usr/bin/env bats

TOOLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../tools" && pwd)"

setup() {
    TMPDIR="$(mktemp -d)"
}

teardown() {
    rm -rf "$TMPDIR"
}

# ── Existence tests ────────────────────────────────────────────────────────────

@test "generate-script.sh exists and is executable" {
    [ -x "$TOOLS_DIR/generate-script.sh" ]
}

@test "validate-script.sh exists and is executable" {
    [ -x "$TOOLS_DIR/validate-script.sh" ]
}

# ── validate-script.sh tests ──────────────────────────────────────────────────

@test "validate-script rejects script with >3 GPUs on single node" {
    cat > "$TMPDIR/bad_gpu.sh" <<'SCRIPT'
#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --gres=gpu:4
#SBATCH --nodes=1
#SBATCH --time=04:00:00
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$TMPDIR/bad_gpu.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"3 GPUs"* ]]
}

@test "validate-script rejects gpu partition without --gres" {
    cat > "$TMPDIR/no_gres.sh" <<'SCRIPT'
#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --time=04:00:00
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$TMPDIR/no_gres.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"--gres"* ]]
}

@test "validate-script rejects --gres without gpu partition" {
    cat > "$TMPDIR/no_partition.sh" <<'SCRIPT'
#!/bin/bash
#SBATCH --gres=gpu:2
#SBATCH --time=04:00:00
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$TMPDIR/no_partition.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"partition=gpu"* ]]
}

@test "validate-script rejects missing --time" {
    cat > "$TMPDIR/no_time.sh" <<'SCRIPT'
#!/bin/bash
#SBATCH --partition=cpu
#SBATCH --mem=4G
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$TMPDIR/no_time.sh"
    [ "$status" -ne 0 ]
    [[ "$output" == *"--time"* ]]
}

@test "validate-script accepts valid GPU script" {
    cat > "$TMPDIR/valid_gpu.sh" <<'SCRIPT'
#!/bin/bash
#SBATCH --partition=gpu
#SBATCH --gres=gpu:2
#SBATCH --time=04:00:00
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$TMPDIR/valid_gpu.sh"
    [ "$status" -eq 0 ]
}

@test "validate-script accepts valid CPU script" {
    cat > "$TMPDIR/valid_cpu.sh" <<'SCRIPT'
#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --mem=4G
SCRIPT
    run "$TOOLS_DIR/validate-script.sh" "$TMPDIR/valid_cpu.sh"
    [ "$status" -eq 0 ]
}

# ── generate-script.sh tests ─────────────────────────────────────────────────

@test "generate-script produces valid GPU script" {
    run "$TOOLS_DIR/generate-script.sh" --gpu 1 --time 4h --framework pytorch
    [ "$status" -eq 0 ]
    [[ "$output" == *"#SBATCH --partition=gpu"* ]]
    [[ "$output" == *"--gres=gpu:1"* ]]
    [[ "$output" == *"cuda"* ]]
}

@test "generate-script produces valid CPU script" {
    run "$TOOLS_DIR/generate-script.sh" --time 1h --cpus 4
    [ "$status" -eq 0 ]
    [[ "$output" == *"--cpus-per-task"* ]]
    [[ "$output" != *"partition=gpu"* ]]
}

@test "generate-script auto-generates multi-node config for >3 GPUs" {
    run "$TOOLS_DIR/generate-script.sh" --gpu 6 --time 8h --framework pytorch
    [ "$status" -eq 0 ]
    [[ "$output" == *"--nodes=2"* ]]
}
