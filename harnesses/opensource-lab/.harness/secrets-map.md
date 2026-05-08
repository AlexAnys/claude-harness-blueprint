# Secrets Map

Single-page view of which lab project touches which bws secret. Cross-reference to each project's `data-touched.md`.

## bws projects in use

| bws project name | UUID | Used by | Key rotation policy |
|---|---|---|---|
| `<your-bws-project>` | `<bws-project-id>` | <your-projects> | rotate yearly + on suspicion |

## Bootstrap

The bws token itself lives in macOS Keychain (`service=bws`), loaded into `BWS_ACCESS_TOKEN` by `~/.zshrc`.

For Bash-tool subshells that don't source `~/.zshrc`, load inline:
```bash
export BWS_ACCESS_TOKEN="$(security find-generic-password -a "$(whoami)" -s "bws" -w 2>/dev/null)"
```

## Secrets x projects matrix

| Secret | bws project | Used by | Last verified rotated | Notes |
|---|---|---|---|---|

## How a project adopts a secret

1. Planner lists it in `projects/<name>/data-touched.md`.
2. Executor checks bws: is secret already in a project we own? → reuse, don't duplicate.
3. If new: `bws secret create <name> <value> <project-uuid>`.
4. Tool invocation wraps in `bws run --project-id <uuid> -- <cmd>`.
5. Append row here.

## Rules

- **Never** paste a secret into chat, plan.md, setup-log.md, or any lab file.
- **Never** write a secret into `~/.zshrc` as a literal — only the bootstrap line that reads Keychain.
- **Single source**: if a secret is migrated from Keychain to bws, delete the Keychain copy after round-trip verification.
- **Rotation schedule**: maintain a reverify entry for any secret >180 days old. Curator's audit routine surfaces these.
- **Scope by blast-radius**: grouping same-class secrets as one project is fine. Sensitive / different-trust-level secrets get their own bws project.
