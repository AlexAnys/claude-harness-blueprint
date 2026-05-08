# Open Source Lab Harness

A production-grade 6-agent Claude Code harness for discovering, installing, comparing, and maintaining open-source projects. Built through real-world usage across 5+ projects, refined through post-mortems and iterative hardening.

## Architecture

```
User → Coordinator → Scout / Planner / Executor / QA / Curator / Comparator
```

| Agent | Role |
|---|---|
| **Coordinator** | User-facing router. Never plans/builds/QAs itself — dispatches and monitors. |
| **Scout** | Given a category ("AI memory layer"), surfaces 3-5 candidates with a pre-install comparison table. |
| **Planner** | Researches a specific project. Produces `plan.md` + `decisions.md` + `data-touched.md`. |
| **Executor** | Follows the plan. Clones, installs, configures, wires secrets, writes `setup-log.md`. |
| **QA** | Independent verification using an 8-dimension scorecard. Has no Edit tool — if a fix is needed, it messages Executor. |
| **Curator** | Keeps installed projects healthy. Re-verify, upstream digest, disk audit, lifecycle transitions. |
| **Comparator** | Cross-project comparison reports along the same 8-dimension rubric. |

## Key Design Decisions

1. **Persistent team, not short-lived subagents.** The coordinator + executor + qa persist as team members across user-approval checkpoints. This was the #1 lesson: without `TeamCreate` at Step 0, the coordinator dies silently at the first checkpoint.

2. **QA has no Edit tool.** Generator/evaluator separation is enforced by tool access, not by instructions alone. QA messages Executor with repro steps; it never fixes code itself.

3. **Experience base is first-class.** `.harness/experience/` holds patterns, failures, playbooks, and runtimes accumulated across real installs. Every agent reads this before acting. The failures log is especially valuable — it prevents the same bug from biting twice.

4. **Secrets via bws only.** No plaintext secrets in any file. Bitwarden Secrets Manager handles injection via `bws run --project-id <id> -- <cmd>`.

5. **Stop hook catches drift.** `qa-gate.sh` fires after every response, warning on unregistered projects, missing setup-logs, port collisions, stale verifications, and missing team persistence.

## Workflow

```
Category → Scout → User picks → Planner → User approves plan → Executor → QA → Registry
```

Or directly: `Repo URL → Planner → approve → Executor → QA → Registry`

Post-install: `Curator re-verify` (monthly/weekly) | `Comparator` (on demand) | `Archive` (lifecycle end)

## What's Included

- **7 agent definitions** (`.claude/agents/`) — battle-tested prompts with real-world lessons baked in
- **Stop hook** (`.claude/hooks/qa-gate.sh`) — drift detection across projects
- **6 scripts** (`scripts/`) — reverify, archive, upstream-digest, similarity-check, port-registry, disk-audit
- **5 templates** (`.harness/templates/`) — plan, decisions, data-touched, envrc, tool-versions
- **Experience base** (`.harness/experience/`) — patterns, failures, playbooks, runtimes from real installs
- **8-dimension scorecard** (`.harness/scorecard-template.md`) — unified QA rubric
- **Acceptance test** (`test.md`) — infrastructure checklist including runtime team-persistence checks

## Getting Started

1. Copy this directory into your project root.
2. Install prerequisites: `gh`, `bws`, `jq`, `direnv`, `mise` (optional but recommended).
3. Set up bws: add your access token to macOS Keychain, update `.harness/secrets-map.md` with your project IDs.
4. Open Claude Code in the lab root — it will land on `@coordinator` automatically.
5. Try: paste a GitHub repo URL, or say "I want an AI memory layer" to kick off scouting.

## Playbooks

The harness ships with 5 install playbooks covering common project shapes:

- **A**: Node SSG / CLI (clone + npm install + build)
- **B**: Bun CLI + local DB (bun link, PGLite/SQLite, MCP)
- **C**: Python agent with TUI (uv venv, installer script)
- **D**: Docker Compose self-host + Homebrew CLI (multi-container stack)
- **E**: Build-from-scratch local-first app (monorepo scaffold, spike gates)

See `.harness/experience/playbooks.md` for full details.

## Post-Mortem: The Silent Failure

The biggest lesson from building this harness: **`TeamCreate` must be Step 0, before any user-facing work.** Placing it after a user-approval checkpoint causes silent failure — the coordinator dies at the checkpoint, messages go to dead inboxes, and no error is surfaced. See `.harness/reports/skill-feedback-harness-design.md` for the full 6-gap analysis.
