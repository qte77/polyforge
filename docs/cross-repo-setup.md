# Cross-Repo Setup

## User-Level Settings

Use `additionalDirectories` + `allowWrite` in
`~/.claude/settings.json` to give any CC session cross-repo
access without per-project config.

```json
{
  "permissions": {
    "additionalDirectories": ["/workspaces"]
  },
  "sandbox": {
    "filesystem": {
      "allowWrite": ["/workspaces"]
    }
  }
}
```

- **additionalDirectories**: Expands Read/Write/Edit
  tool scope beyond CWD
- **allowWrite**: Expands Bash sandbox write access
  (additive across scopes)

Since `allowWrite` merges across scopes, project-level
`sandbox.filesystem` is redundant. User-level is the
single source of truth for sandbox config.

## Credentials

Codespaces encrypted secrets via `containerEnv` in
`devcontainer.json` (`GH_PAT`, `WAKATIME_API_KEY`).
Alternative: copy `.env.example` to `.env` and
`source .env`.
