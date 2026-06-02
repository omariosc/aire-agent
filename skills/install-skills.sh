#!/usr/bin/env bash
# Symlink aire-agent skills into standard agent skill directories.
set -euo pipefail

AIRE_AGENT="${AIRE_AGENT:-${HOME}/.aire-agent}"
SKILLS_SRC="${AIRE_AGENT}/skills"

if [[ ! -d "${SKILLS_SRC}" ]]; then
  echo "error: skills directory not found: ${SKILLS_SRC}" >&2
  exit 1
fi

TARGETS=(
  "${HOME}/.agents/skills"
  "${HOME}/.codex/skills"
  "${HOME}/.claude/skills"
  "${HOME}/.cursor/skills"
  "${HOME}/.gemini/skills"
)

installed=0
for target in "${TARGETS[@]}"; do
  mkdir -p "${target}"
  for skill_dir in "${SKILLS_SRC}"/aire-*/; do
    [[ -d "${skill_dir}" ]] || continue
    [[ -f "${skill_dir}/SKILL.md" ]] || continue
    name="$(basename "${skill_dir}")"
    name="$(basename "${skill_dir}")"
    rm -rf "${target}/${name}"
    ln -sfn "$(cd "${skill_dir}" && pwd)" "${target}/${name}"
    echo "linked ${name} -> ${target}/"
    installed=$((installed + 1))
  done
done

echo ""
echo "Done. Linked skills from ${SKILLS_SRC}"
echo "Set AIRE_AGENT=${AIRE_AGENT} in your shell profile if not already set."
