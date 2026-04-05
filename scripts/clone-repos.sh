#!/bin/bash
# Clone all managed repos from config/repos.conf
# Uses GH_REPOS (owner/repo) for clone URL, REPOS for local path

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load-workspace-repos.sh"
source "${SCRIPT_DIR}/colors.sh"

for i in "${!GH_REPOS[@]}"; do
  gh_repo="${GH_REPOS[$i]}"
  path="${REPOS[$((i+1))]}"
  name="${REPO_NAMES[$((i+1))]}"
  fork_flag="${FORK_FLAGS[$i]:-}"

  if [[ -d "$path" ]]; then
    info "${name}: exists (skipping)"
    continue
  fi

  mkdir -p "$(dirname "$path")"

  if [[ "$fork_flag" == "fork" ]]; then
    # Fork under authenticated user, then clone the fork
    repo_basename="${gh_repo##*/}"
    fork_owner=$(gh api user --jq .login 2>/dev/null || echo "qte77")
    fork_slug="${fork_owner}/${repo_basename}"

    info "${name}: forking ${gh_repo}..."
    gh repo fork "${gh_repo}" --clone=false 2>/dev/null || true

    info "${name}: cloning fork ${fork_slug}..."
    git clone "https://github.com/${fork_slug}.git" "$path" 2>/dev/null || {
      error "Failed to clone fork ${fork_slug}"
      continue
    }

    info "${name}: adding upstream remote..."
    git -C "$path" remote add upstream "https://github.com/${gh_repo}.git" 2>/dev/null || true
    git -C "$path" fetch upstream 2>/dev/null || warn "${name}: upstream fetch failed"
  else
    info "${name}: cloning ${gh_repo}..."
    git clone "https://github.com/${gh_repo}.git" "$path" 2>/dev/null || \
      error "Failed to clone ${gh_repo}"
  fi
done

success "Done. $(ls -d "${REPOS[@]:1}" 2>/dev/null | wc -l)/${#GH_REPOS[@]} repos available."
