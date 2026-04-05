#!/bin/bash
# cc-parallel.sh — Run a claude prompt across repos in parallel
# Usage: ./cc-parallel.sh <prompt> <repo-path> [repo-path...]
# Usage: ./cc-parallel.sh --preset <preset-name>
#
# Options:
#   --max-turns N      Max conversation turns per repo (default: 10)
#   --output-dir DIR   Directory for result files (default: mktemp)
#   --preset NAME      Use a predefined prompt+repo combination
#
# Presets:
#   validate    — Run `make validate` on all repos that have a Makefile
#   security    — Audit for security issues
#
# Examples:
#   ./cc-parallel.sh "Run make validate" /workspaces/Agents-eval /workspaces/qte77/RAPID-spec-forge
#   ./cc-parallel.sh --preset validate
#   ./cc-parallel.sh "Check for TODO comments" /workspaces/Agents-eval

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load-workspace-repos.sh"
source "${SCRIPT_DIR}/colors.sh"

# Defaults
MAX_TURNS=10
OUTPUT_DIR=""
PROMPT=""
PRESET=""
TARGET_REPOS=()
CONTRIB_MODE=""
CONTRIB_ISSUES=""
CONTRIB_PROJECT=""
declare -A REPO_PROMPTS

usage() {
  head -20 "$0" | grep '^#' | sed 's/^# \?//'
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-turns) MAX_TURNS="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --preset) PRESET="$2"; shift 2 ;;
    --mode) CONTRIB_MODE="$2"; shift 2 ;;
    --issues) CONTRIB_ISSUES="$2"; shift 2 ;;
    --project) CONTRIB_PROJECT="$2"; shift 2 ;;
    --help|-h) usage ;;
    -*)
      error "Unknown option: $1"
      usage
      ;;
    *)
      if [[ -z "$PROMPT" && -z "$PRESET" ]]; then
        PROMPT="$1"
      else
        TARGET_REPOS+=("$1")
      fi
      shift
      ;;
  esac
done

# Apply presets
case "$PRESET" in
  validate)
    PROMPT="Run 'make validate' and report the results. If make validate is not available, run the closest equivalent (lint, type check, test)."
    for repo in "${REPOS[@]}"; do
      [[ -f "$repo/Makefile" ]] && TARGET_REPOS+=("$repo")
    done
    ;;
  security)
    PROMPT="Audit this repo for security issues: hardcoded secrets, insecure dependencies, OWASP top 10 vulnerabilities. Report findings with severity (critical/high/medium/low) and file locations."
    TARGET_REPOS=("${REPOS[@]}")
    MAX_TURNS=15
    ;;
  contribute)
    if [[ -z "$CONTRIB_MODE" ]]; then
      error "contribute preset requires --mode <triage|implement|review>"
      usage
    fi

    PROMPTS_DIR="${SCRIPT_DIR}/../config/prompts"
    TEMPLATE="${PROMPTS_DIR}/contribute-${CONTRIB_MODE}.md"
    if [[ ! -f "$TEMPLATE" ]]; then
      error "Template not found: $TEMPLATE"
      exit 1
    fi

    # Set max turns per mode
    case "$CONTRIB_MODE" in
      triage) MAX_TURNS=15 ;;
      implement) MAX_TURNS=50 ;;
      review) MAX_TURNS=20 ;;
      *) error "Unknown mode: $CONTRIB_MODE"; usage ;;
    esac

    # Build target repos: fork-flagged only, optionally filtered by --project
    for i in "${!GH_REPOS[@]}"; do
      [[ "${FORK_FLAGS[$i]:-}" != "fork" ]] && continue
      repo_name="${REPO_NAMES[$((i+1))]}"
      if [[ -n "$CONTRIB_PROJECT" && "$repo_name" != "$CONTRIB_PROJECT" ]]; then
        continue
      fi
      TARGET_REPOS+=("${REPOS[$((i+1))]}")
    done

    # Build per-repo prompts with variable substitution
    # We store prompts in an associative array keyed by repo path
    declare -A REPO_PROMPTS
    for repo in "${TARGET_REPOS[@]}"; do
      repo_name=$(basename "$repo")
      env_file="${PROMPTS_DIR}/${repo_name}.env"

      # Load per-project env (defaults if missing)
      TECH_STACK="unknown"
      SKILLS=""
      UPSTREAM=""
      DEFAULT_ISSUES=""
      if [[ -f "$env_file" ]]; then
        source "$env_file"
      fi

      # Use --issues override or fall back to DEFAULT_ISSUES
      issues="${CONTRIB_ISSUES:-$DEFAULT_ISSUES}"

      # Substitute template variables
      prompt=$(cat "$TEMPLATE")
      prompt="${prompt//\{\{TECH_STACK\}\}/$TECH_STACK}"
      prompt="${prompt//\{\{SKILLS\}\}/$SKILLS}"
      prompt="${prompt//\{\{UPSTREAM\}\}/$UPSTREAM}"
      prompt="${prompt//\{\{ISSUES\}\}/$issues}"
      REPO_PROMPTS["$repo"]="$prompt"
    done

    # Use first repo's prompt as the display prompt (truncated in header)
    if [[ ${#TARGET_REPOS[@]} -gt 0 ]]; then
      PROMPT="${REPO_PROMPTS[${TARGET_REPOS[0]}]}"
    fi
    ;;
  "")
    # No preset, need prompt and repos from args
    ;;
  *)
    error "Unknown preset: $PRESET"
    usage
    ;;
esac

if [[ -z "$PROMPT" ]]; then
  error "No prompt provided."
  usage
fi

if [[ ${#TARGET_REPOS[@]} -eq 0 ]]; then
  error "No repos specified."
  usage
fi

# Setup output directory
if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR=$(mktemp -d -t cc-parallel-XXXXXX)
fi
mkdir -p "$OUTPUT_DIR"

info "=== CC Parallel Runner ==="
info "Prompt:     ${PROMPT:0:80}$([ ${#PROMPT} -gt 80 ] && echo '...')"
info "Repos:      ${#TARGET_REPOS[@]}"
info "Max turns:  $MAX_TURNS"
info "Output:     $OUTPUT_DIR"
echo ""

# Track PIDs for wait
declare -A PIDS

# Launch parallel claude instances
for repo in "${TARGET_REPOS[@]}"; do
  if [[ ! -d "$repo" ]]; then
    warn "$repo not found, skipping"
    continue
  fi

  name=$(basename "$repo")
  outfile="${OUTPUT_DIR}/${name}.json"
  logfile="${OUTPUT_DIR}/${name}.log"

  # Use per-repo prompt if available (contribute preset), else global PROMPT
  repo_prompt="${REPO_PROMPTS[$repo]:-$PROMPT}"

  info "Starting: $name"

  (
    cd "$repo"
    claude -p "$repo_prompt" \
      --output-format json \
      --max-turns "$MAX_TURNS" \
      > "$outfile" 2>"$logfile"
  ) &
  PIDS[$name]=$!
done

echo ""
info "Waiting for ${#PIDS[@]} instances..."
echo ""

# Collect results
TOTAL_COST=0
FAILURES=0

for name in "${!PIDS[@]}"; do
  pid="${PIDS[$name]}"
  outfile="${OUTPUT_DIR}/${name}.json"

  if wait "$pid"; then
    status="OK"
  else
    status="FAILED"
    ((FAILURES++))
  fi

  # Extract cost and result summary from JSON output
  cost="n/a"
  result_preview=""
  if [[ -f "$outfile" && -s "$outfile" ]]; then
    cost=$(jq -r '.cost_usd // .session_cost // "n/a"' "$outfile" 2>/dev/null || echo "n/a")
    result_preview=$(jq -r '.result // .content // "" | tostring | .[0:120]' "$outfile" 2>/dev/null || echo "")

    if [[ "$cost" != "n/a" ]]; then
      TOTAL_COST=$(echo "$TOTAL_COST + $cost" | bc 2>/dev/null || echo "$TOTAL_COST")
    fi
  fi

  printf "%-30s %-8s \$%-8s %s\n" "$name" "$status" "$cost" "${result_preview:0:60}"
done

echo ""
info "=== Summary ==="
info "Total repos:    ${#PIDS[@]}"
if [[ "$FAILURES" -gt 0 ]]; then
  error "Failures:       $FAILURES"
else
  success "Failures:       $FAILURES"
fi
info "Total cost:     \$${TOTAL_COST}"
info "Results in:     $OUTPUT_DIR"

exit "$FAILURES"
