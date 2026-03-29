<!-- markdownlint-disable MD033 -->
# polyforge

Orchestrate AI coding agents across N repos
in parallel from one Codespace.

**For** teams running AI coding agents across a
polyrepo codebase in Codespaces or devcontainers.
**Run** `./scripts/cc-parallel.sh --preset validate`
to validate all repos in one command.

## Quick Start

```bash
./scripts/cc-parallel.sh --preset validate
./scripts/cc-parallel.sh --preset security
./scripts/cc-status.sh
```

Repos: edit `workspace.code-workspace`. Credentials:
set `GH_PAT` as Codespace secret.

<details>
  <picture>
    <source media="(prefers-color-scheme: dark)"
      srcset="assets/images/polyforge-dark.svg">
    <source media="(prefers-color-scheme: light)"
      srcset="assets/images/polyforge-light.svg">
    <img alt="polyforge workspace"
      src="assets/images/polyforge-dark.svg"
      width="100%">
  </picture>
</details>

## Docs

- [Codespaces](docs/codespaces.md) — rebuild, secrets, management
- [Cross-repo setup](docs/cross-repo-setup.md) — auth, sandbox, settings
- [Cloud workflows](docs/cc-web-cloud-workflows.md) — remote execution
- [Sandbox friction](docs/sandbox-friction.md) — known issues, mitigations
