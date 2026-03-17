#!/bin/bash
# Clone all managed repos into the workspace
# Sourced repo list from repos.conf, GitHub org derived from polyforge remote

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/repos.conf"

# GitHub repo names matching repos.conf order
GITHUB_REPOS=(
  qte77/Agents-eval
  qte77/claude-code-research
  qte77/CABIO-test
  qte77/ralph-loop-cc-tdd-wt-vibe-kanban-template
  qte77/claude-code-utils-plugin
  qte77/deepvariant-linux-arm64
)

for i in "${!GITHUB_REPOS[@]}"; do
  path="${REPOS[$i]}"
  gh_repo="${GITHUB_REPOS[$i]}"

  if [[ -d "$path" ]]; then
    echo "  ${REPO_NAMES[$i]}: exists (skipping)"
    continue
  fi

  echo "  ${REPO_NAMES[$i]}: cloning..."
  mkdir -p "$(dirname "$path")"
  git clone "https://github.com/${gh_repo}.git" "$path" 2>/dev/null || \
    echo "  WARNING: Failed to clone ${gh_repo}"
done

echo "Done. $(ls -d "${REPOS[@]}" 2>/dev/null | wc -l)/${#REPOS[@]} repos available."
