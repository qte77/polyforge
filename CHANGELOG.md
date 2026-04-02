<!-- markdownlint-disable MD024 no-duplicate-heading -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Types of changes**: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`

## [Unreleased]

### Added

- `setup_dotfiles` Makefile target — deploys dotfiles symlinks after `clone_repos` (idempotent)
- `start_workspace` added to `postAttachCommand` — opens workspace file on attach
- WakaTime API key non-interactive setup via `WAKATIME_API_KEY` Codespace secret

### Changed

- `setup_all` pipeline reordered: `clone_repos → setup_dotfiles → setup_claude_code → setup_rtk` — dotfiles deploy before RTK so `settings.json` is merged, not overwritten
- `postAttachCommand` now runs `setup_repos setup_dotfiles start_workspace` — re-deploys dotfiles (covers VS Code extension timing race) and opens workspace
- `scripts/repos.conf`: dynamic `POLYFORGE_ROOT` detection (works at any checkout path)
- `onCreateCommand` uses `;` separators (each step runs independently)

### Removed

- Workspace tasks (`runOn: folderOpen`) — do not fire in Codespaces

### Fixed

- `~/.claude/settings.json` not deployed on container create — VS Code dotfiles extension races with `onCreateCommand`, so dotfiles `install.sh` never ran; RTK then wrote to an empty file
- `clone-repos.sh`: seed `~/.wakatime.cfg` with tracking-safe defaults — `include_only_with_project_file` and `exclude_unknown_project` silently block all heartbeats when `true` (closes #30)
- Sidebar folders not loading when polyforge is the main Codespace repo (path mismatch)
- Container recovery mode from `set -e` in `clone-repos.sh` and `&&` chain in `onCreateCommand`

## [0.0.1] - 2026-03-17

### Added

- `scripts/cc-repos.sh`: tmux session with one window per managed repo
- `scripts/cc-parallel.sh`: parallel `claude -p` across repos with presets (validate, status, security)
- `scripts/cc-credential-setup.sh`: unified git credential store, embedded PAT cleanup
- `scripts/cc-status.sh`: status dashboard (branch, dirty state, Ralph progress, last commit)
- `scripts/repos.conf`: single source of truth for managed repo list
- `config/env-loader.sh`: auth resolution (.env -> ~/.gh_pat -> env vars)
- `config/settings.user.json`: reference template for user-level CC settings
- `workspace.code-workspace`: VS Code multi-root workspace with all repos
- `.devcontainer/`: Codespace setup with repo cloning, dotfiles, tmux auto-start
- `docs/cross-repo-setup.md`: additionalDirectories + allowWrite pattern
- `docs/sandbox-friction.md`: 4 friction points with mitigations and research sources
- `docs/settings-consolidation.md`: DRY settings — user-level as single source of truth
