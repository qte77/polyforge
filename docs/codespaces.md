# Codespaces

## Rebuild

After changing `devcontainer.json`, rebuild to apply:

```bash
gh codespace rebuild
gh codespace rebuild --full  # clean rebuild (no cache)
```

Or via VS Code command palette:
**Ctrl+Shift+P** → `Codespaces: Rebuild Container`

Note: `Dev Containers: Rebuild Container` works for
local devcontainers, not Codespaces.

## Management

```bash
gh codespace list
gh codespace stop
gh codespace delete
gh codespace ssh
gh codespace logs
```

## Secrets

Secrets are set at user level and scoped to repos:

```bash
gh secret set GH_PAT --user --repos qte77/polyforge
gh secret list --user
```

Secrets are injected as env vars. Map them in
`devcontainer.json` via `containerEnv`:

```json
"containerEnv": {
    "GH_PAT": "${localEnv:GH_PAT}",
    "GH_TOKEN": "${localEnv:GH_PAT}"
}
```

See `docs/cross-repo-setup.md` for auth details.

## Ports and Forwarding

```bash
gh codespace ports
gh codespace ports forward 8080:8080
```

## References

- [Codespaces docs](https://docs.github.com/en/codespaces)
- [gh codespace CLI](https://cli.github.com/manual/gh_codespace)
