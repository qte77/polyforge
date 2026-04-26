# PAT Scoping & Hardening

Manual hardening checklist that pairs with the [GH_PAT precedence
convention](codespaces.md#token-precedence--what-wins-when-multiple-are-set).
Every step here is a GitHub UI action — automation isn't appropriate
because credentials and protection rules are operator-controlled by
design.

## Per-repo fine-grained PAT

Use one fine-grained PAT per logical scope (per-repo or per-org), not
one classic PAT for everything. Classic PATs grant broad scopes;
fine-grained PATs scope to specific repositories with minimum
permissions.

**When to create:**
- Cross-repo automation (e.g. `cc-parallel.sh` write operations)
- CI jobs that push or open PRs
- Anything that needs scopes the Codespaces-injected `GITHUB_TOKEN`
  doesn't carry (see `codespaces.md` token-scopes table)

**Where to create:**
GitHub → Settings → Developer settings → Personal access tokens →
**Fine-grained tokens** → Generate new token.

**Minimum recommended permissions:**

| Permission | Access | Why |
|---|---|---|
| Contents | Read & write | `git push`, `git pull` |
| Pull requests | Read & write | `gh pr create`, review/merge |
| Issues | Read & write | issue creation, labels, comments |
| Metadata | Read | implicit dependency for all of the above |
| Workflows | Read & write | only if the PAT touches `.github/workflows/*` |

**Repo selection:** specific repos only. Never "All repositories" or
"Public repositories."

**Expiration:** 90 days max. Rotation policy below.

**Storage:** the PAT goes into `gh secret set GH_PAT --user --repos
<owner>/<repo>` (per `codespaces.md`). It is never committed.

## Branch protection on `main`

For every repo that receives PR-bot writes, enable branch protection
on the default branch:

GitHub → Settings → Branches → Add rule (target: `main`):

- [ ] **Require a pull request before merging** — direct pushes blocked
- [ ] **Require linear history** — no merge commits, squash or rebase only
- [ ] **Require signed commits** — ties into the GPG signing policy
      (qte77/qte77/docs/gpg-signing.md); the PR can't merge without
      verified signatures on every commit
- [ ] **Block force pushes** — keep history immutable
- [ ] **Block deletions** — `main` can't be deleted via API
- [ ] **Do not allow bypassing the above settings** — applies to admins
      too; prevents accidental override

## Secret-scanning push protection

GitHub → Settings → Code security and analysis:

- [ ] **Secret scanning** — On
- [ ] **Push protection** — On (blocks pushes that contain detected
      secrets before they hit the remote)

This catches the most common credential-leak failure mode: an agent
or human accidentally pasting a token into a commit. Free for public
repos; included with GitHub Advanced Security for private.

## Rotation cadence

- **Quarterly review** — list all fine-grained PATs (Settings →
  Developer settings → Personal access tokens → Fine-grained tokens),
  prune unused ones, regenerate any that are over 60 days old
- **Immediate rotation** on any of:
  - Suspected compromise (logs show unauthorized actions)
  - Codespace recovered from a public branch
  - Departure of any operator who held the PAT
- **Document rotations** in the repo's CHANGELOG or a private notes
  channel — not in a commit, never in code

## See also

- [`codespaces.md`](codespaces.md) — token precedence, scopes, secrets
- [`cross-repo-setup.md`](cross-repo-setup.md) — auth details across
  multi-repo workflows
- `qte77/qte77/docs/gpg-signing.md` — signed-commit policy that
  branch protection's "require signed commits" rule enforces
