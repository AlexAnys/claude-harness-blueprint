# Open Source Lab — Harness Acceptance Test

What the lab infrastructure must do. Each item is observable, binary, specific. First thing to run after any harness change.

## What the user asked for (original intent)

> Automatically manage multiple open-source projects — each independently isolated, testable, and comparable.

Translated into concrete goals:

1. **Multiple independent projects**: each project has its own code, state, runtime pin, port, secrets scope.
2. **Testing + comparing**: the lab can QA one project and compare multiple.
3. **Automatic management**: re-verify / upstream digest / disk audit run without re-remembering how.
4. **Lifecycle**: scouting → installed → adopted → deprecated → archived, with an audit trail.

---

## Infrastructure checklist

Run top-to-bottom. Every item: pass / fail / partial.

### Core team

- [ ] `.claude/agents/coordinator.md` defines the user-facing router
- [ ] `.claude/agents/scout.md` exists
- [ ] `.claude/agents/planner.md` exists
- [ ] `.claude/agents/executor.md` exists
- [ ] `.claude/agents/qa.md` exists and references gstack `/qa-only`
- [ ] `.claude/agents/curator.md` exists
- [ ] `.claude/agents/comparator.md` exists
- [ ] All agents use `model: opus[1m]` (per global rule)
- [ ] Executor has Edit; QA does NOT have Edit (verifier/fixer separation)
- [ ] Generator + QA both have SendMessage (peer-to-peer coordination)

### Enforcement

- [ ] `.claude/settings.json` present
- [ ] `.claude/settings.json` has top-level `"agent": "coordinator"` (Layer 1 baseline — opens straight into coordinator, no @-mention required)
- [ ] `.claude/hooks/qa-gate.sh` exists, is executable, exits 0
- [ ] Stop hook wired to `.claude/hooks/qa-gate.sh`
- [ ] Stop hook produces `::lab-gate::` warnings on drift (e.g. project without registry row)
- [ ] Stop hook warns if lab activity exists but `~/.claude/teams/lab/` is missing (silent-failure detector)

### Runtime team persistence (the layer test.md USED to miss — see post-mortem)

These items can only be verified by **actually running** the lab — file presence is not enough. They catch the silent-failure mode where every file looks correct but the team was never created.

- [ ] After opening Claude Code in lab root, prompt prefix shows `@coordinator` (proves `"agent": "coordinator"` works)
- [ ] After coordinator's first user message handled, `~/.claude/teams/lab/config.json` exists
- [ ] That config has 3 members: `coordinator`, `executor`, `qa` (read with `jq '.members[].name' ~/.claude/teams/lab/config.json`)
- [ ] After a plan-checkpoint pause (user approves a plan), the SAME coordinator instance continues — verify by sending "what's the status?" and checking it remembers the plan context (no fresh re-introduction)
- [ ] `SendMessage` from another agent to `coordinator` is delivered (not bounced to dead inbox)
- [ ] If `~/.claude/teams/lab/` is deleted mid-session, next coordinator turn re-creates it via Step 0 bootstrap (recovery path works)

### Blackboard

- [ ] `registry.md` has lifecycle column with states `installed`, `adopted`, `deprecated`, `archived`
- [ ] `registry.md` has `Last verified` column (date)
- [ ] `.harness/progress.tsv` schema: `timestamp project phase status disk_mb duration_sec notes`
- [ ] `.harness/ports.tsv` exists with header `project port protocol purpose claimed`
- [ ] `.harness/secrets-map.md` documents bws project IDs + consumers
- [ ] `.harness/scorecard-template.md` defines 8 dimensions (Works, Accessible, Minimal config, Documented, Cost, Isolation, Reversibility, Upstream health)
- [ ] `.harness/reverify-schedule.tsv` tracks next_due per project

### Experience (domain research, pre-populated)

- [ ] `.harness/experience/patterns.md` has playbook-by-runtime table + smoke-test ladder
- [ ] `.harness/experience/failures.md` has at least the bws/Bash-subshell gotcha documented
- [ ] `.harness/experience/playbooks.md` has Playbook A (Node SSG), B (Bun CLI), C (Python uv)
- [ ] `.harness/experience/runtimes.md` lists system baseline + per-project pins

### Templates

- [ ] `.harness/templates/envrc.template` exists
- [ ] `.harness/templates/tool-versions.template` exists
- [ ] `.harness/templates/plan.md.template` exists (with data-touched pointer)
- [ ] `.harness/templates/decisions.md.template` exists (with Revisit trigger field)
- [ ] `.harness/templates/data-touched.md.template` exists

### Scripts (cron-able surface for "automatic management")

- [ ] `scripts/reverify.sh <name>` re-runs verification, writes `reverify-<date>.md`
- [ ] `scripts/reverify.sh --all` handles every installed/adopted project
- [ ] `scripts/archive.sh <name>` moves to `_archive/` + appends to progress.tsv
- [ ] `scripts/upstream-digest.sh` calls GitHub releases API per project
- [ ] `scripts/similarity-check.sh <name>` searches registry + plan.md files
- [ ] `scripts/port-registry.sh {list|next|claim|check}` works
- [ ] `scripts/disk-audit.sh` writes `.harness/reports/audit-<date>.md`
- [ ] All scripts in `scripts/` are executable
- [ ] All scripts print `usage:` when called without args

### Existing projects wired into new infra

- [ ] `registry.md` has rows for your installed projects with correct lifecycle
- [ ] Each installed project row has Last verified date
- [ ] Projects with bws secrets mention the bws project name
- [ ] Planning-stage projects marked `planning` (not yet installed)
- [ ] `.harness/experience/failures.md` captures real failures from your projects
- [ ] `.harness/experience/patterns.md` cites real setup-log.md files

### Isolation primitives

- [ ] CLAUDE.md documents the `.envrc` + `.tool-versions` + per-project state dir convention
- [ ] `.harness/templates/envrc.template` includes secret-injection guidance (bws, not literals)
- [ ] `projects/_archive/` directory exists for archived projects
- [ ] `projects/_scouting/` convention documented (per-category subfolder)

### Smoke tests (functional, not just file-present)

Run these commands; each must succeed:

- [ ] `scripts/port-registry.sh check` returns 0 with "no collisions"
- [ ] `scripts/port-registry.sh next` returns a free port integer
- [ ] `scripts/similarity-check.sh <any-installed-project>` surfaces the project row in registry
- [ ] `scripts/disk-audit.sh` writes a report under `.harness/reports/`
- [ ] `.claude/hooks/qa-gate.sh` returns 0 and emits 0 or more `::lab-gate::` lines
- [ ] No project folder exists without a `plan.md` (Stop hook catches this)
- [ ] No unregistered project in `projects/` (Stop hook catches this)

## Failure modes this harness catches

These are the drift / rot patterns the lab is built to prevent. Each cites which piece of infrastructure catches it.

| Failure mode | Caught by |
|---|---|
| Installing a duplicate of an existing project without noticing | `scripts/similarity-check.sh` |
| Two projects both claim the same port | `scripts/port-registry.sh check` + Stop hook |
| `~/.zshrc` not sourced in Bash-tool subshells | `.harness/experience/failures.md` — planner reads it |
| Key rotates and a project silently breaks | `scripts/upstream-digest.sh` + `scripts/reverify.sh` on schedule |
| A deprecated project lingers with stale state | `scripts/archive.sh` gated on lifecycle = deprecated |
| Project installed but missing setup-log.md | Stop hook warning |
| Re-install produces different behavior than original | `scripts/reverify.sh` diff |
| Secret leaks into a lab file | plaintext-in-file patterns (future: grep hook) + bws-only convention |

## Re-test trigger

Re-run this checklist after:
- Any edit to files in `.claude/agents/`, `.claude/hooks/`, `.claude/settings.json`, `scripts/`, `.harness/templates/`, or `CLAUDE.md`
- Adding or archiving any project
- Upgrading the harness-design skill (upstream changes)
