#!/bin/bash
# Load REPOS and REPO_NAMES arrays from workspace.code-workspace
# Usage: source scripts/load-workspace-repos.sh

POLYFORGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE_FILE="${POLYFORGE_ROOT}/workspace.code-workspace"

if [[ ! -f "$WORKSPACE_FILE" ]]; then
  echo "Error: $WORKSPACE_FILE not found" >&2
  exit 1
fi

mapfile -t REPOS < <(jq -r '.folders[].path' "$WORKSPACE_FILE")
mapfile -t REPO_NAMES < <(jq -r '.folders[].name' "$WORKSPACE_FILE")
