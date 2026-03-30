#!/bin/bash
# Generate workspace.code-workspace and .vscode/tasks.json from config/repos.conf (SOT)
# workspace.code-workspace: folder list only
# .vscode/tasks.json: terminal tasks with runOn: folderOpen, group: repos (split terminals)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load-workspace-repos.sh"

WORKSPACE_FILE="${POLYFORGE_ROOT}/workspace.code-workspace"
TASKS_FILE="${POLYFORGE_ROOT}/.vscode/tasks.json"

mkdir -p "${POLYFORGE_ROOT}/.vscode"

# Build folders array — polyforge + relative paths from gh_repo entries
folders='[{"path": ".", "name": "polyforge"}]'
for i in "${!GH_REPOS[@]}"; do
  folders=$(echo "$folders" | jq \
    --arg p "../${GH_REPOS[$i]}" \
    --arg n "${REPO_NAMES[$((i+1))]}" \
    '. + [{"path": $p, "name": $n}]')
done

# Write workspace file (folders only)
jq -n --argjson folders "$folders" '{folders: $folders}' > "$WORKSPACE_FILE"

# Build tasks array with resolved absolute paths
tasks="[]"
for i in "${!REPOS[@]}"; do
  tasks=$(echo "$tasks" | jq \
    --arg label "${REPO_NAMES[$i]}" \
    --arg cwd "${REPOS[$i]}" \
    '. + [{
      "label": $label,
      "type": "shell",
      "command": "exec $SHELL",
      "options": { "cwd": $cwd },
      "runOptions": { "runOn": "folderOpen" },
      "presentation": { "group": "repos", "reveal": "always" },
      "problemMatcher": []
    }]')
done

# Write tasks file
jq -n --argjson tasks "$tasks" '{version: "2.0.0", tasks: $tasks}' > "$TASKS_FILE"

echo "Generated $WORKSPACE_FILE with ${#REPOS[@]} folders"
echo "Generated $TASKS_FILE with ${#REPOS[@]} tasks"
