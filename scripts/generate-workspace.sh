#!/bin/bash
# Generate .vscode/tasks.json (split terminals) and workspace.code-workspace (sidebar folders)
# Both derived from repos.conf — single source of truth for repo paths

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
source "${SCRIPT_DIR}/repos.conf"

# --- .vscode/tasks.json (auto-opens split terminals on folder open) ---
mkdir -p "${ROOT_DIR}/.vscode"
TASKS_FILE="${ROOT_DIR}/.vscode/tasks.json"

tasks=""
for i in "${!REPOS[@]}"; do
  path="${REPOS[$i]}"
  name="${REPO_NAMES[$i]}"

  [[ -n "$tasks" ]] && tasks+=","
  tasks+=$'\n'"      {"
  tasks+=$'\n'"        \"label\": \"${name}\","
  tasks+=$'\n'"        \"type\": \"shell\","
  tasks+=$'\n'"        \"command\": \"exec \$SHELL\","
  tasks+=$'\n'"        \"options\": { \"cwd\": \"${path}\" },"
  tasks+=$'\n'"        \"runOptions\": { \"runOn\": \"folderOpen\" },"
  tasks+=$'\n'"        \"presentation\": { \"group\": \"repos\", \"reveal\": \"always\" },"
  tasks+=$'\n'"        \"problemMatcher\": []"
  tasks+=$'\n'"      }"
done

cat > "$TASKS_FILE" <<EOF
{
  "version": "2.0.0",
  "tasks": [${tasks}
  ]
}
EOF
echo "Generated $TASKS_FILE with ${#REPOS[@]} terminal tasks"

# --- workspace.code-workspace (optional, for multi-root sidebar) ---
WORKSPACE_FILE="${ROOT_DIR}/workspace.code-workspace"

folders=""
for i in "${!REPOS[@]}"; do
  [[ -n "$folders" ]] && folders+=","
  folders+=$'\n'"    { \"path\": \"${REPOS[$i]}\", \"name\": \"${REPO_NAMES[$i]}\" }"
done

cat > "$WORKSPACE_FILE" <<EOF
{
  "folders": [${folders}
  ]
}
EOF
echo "Generated $WORKSPACE_FILE with ${#REPOS[@]} folders (open manually for multi-root sidebar)"
