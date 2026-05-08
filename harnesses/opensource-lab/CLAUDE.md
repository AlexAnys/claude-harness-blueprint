# Open Source Lab

A harness-driven workflow for discovering, installing, comparing, and maintaining open-source projects. Each project lives isolated in its own folder; the lab itself maintains a registry, experience base, and lifecycle state across them.

## Bootstrap Protocol (READ FIRST — non-negotiable)

The lab's 6-agent team is **persistent**, not short-lived. `settings.json` sets `"agent": "coordinator"` so opening Claude Code lands directly on the coordinator. The coordinator's `.claude/agents/coordinator.md` Step 0 then runs `TeamCreate("lab")` + spawns @executor and @qa as team members.

**Hard rule for the team-lead** (top-level Claude Code is always the team-lead — only it has the `Agent` and `TeamCreate` tools across the lab; team-spawned members get a restricted toolset and CANNOT spawn each other):

> Before invoking ANY lab agent (`Agent({subagent_type: "coordinator" / "executor" / "qa" / ...})`):
>
> 1. Check `~/.claude/teams/lab/config.json` exists with `team-lead + coordinator + executor + qa` members.
> 2. If team file missing → `TeamCreate("lab", agent_type: "team-lead")`.
> 3. For each of `coordinator`, `executor`, `qa` missing from the member list → spawn with `Agent({team_name: "lab", name: "<role>", subagent_type: "<role>", prompt: "..."})`. **All three must be spawned by team-lead** — coordinator cannot spawn executor/qa because the platform strips `Agent` from team members.
> 4. After team is complete, dispatch the user's actual work via `SendMessage({to: "coordinator", message: "..."})`.
> 5. NEVER call `Agent({subagent_type: "coordinator"})` without `team_name: "lab"` — that creates a short-lived subagent that dies at the first user-approval checkpoint, with no way to resume.
>
> **Symptom of skipping this**: coordinator does plan + asks for approval, then is dead. You SendMessage to it, the message goes to a dead inbox, the install never starts. No error is shown — pure silent failure.

This was the #1 production failure — see `.harness/experience/failures.md` for the post-mortem and `.harness/reports/skill-feedback-harness-design.md` for the underlying skill gaps (6 discoveries total, including the team-spawn tool-stripping behavior found during recovery).

## What this lab is for

- **Scouting**: given a category ("AI memory layer", "Obsidian alternative"), surface 3-5 candidates with a comparison table before installing.
- **Installing**: minimal-config setup under `projects/<name>/`, isolated from other projects.
- **Comparing**: generate side-by-side scorecards across installed projects using a unified rubric.
- **Maintaining**: re-verify installed projects on a cadence; track upstream releases; archive deprecated ones.
- **Learning**: accumulate patterns and failures across projects in `.harness/experience/`.

## Agent Team

Six agents collaborate as a persistent team (not short-lived subagents). The user talks to the Coordinator only; the rest coordinate directly via SendMessage + files.

| Agent | Role | When |
|---|---|---|
| **@coordinator** | User-facing router; never plans/builds/QAs itself | Every user request |
| **@scout** | Category research → candidate table | User says "I want an X" (category) |
| **@planner** | Research a specific project → plan.md + decisions.md + data-touched.md | After scout picks, or direct repo URL |
| **@executor** | Install per plan, wire secrets, write setup-log.md | Plan approved |
| **@qa** | Independent verification with scorecard + gstack `/qa-only` for web UIs | After executor reports |
| **@curator** | Re-verify, upstream digest, disk audit, lifecycle transitions | Scheduled / on demand |
| **@comparator** | Cross-project comparison reports | User asks "A vs B" |

Full definitions in `.claude/agents/<name>.md`. All use `model: opus[1m]`.

## Directory Structure

```
opensource-lab/
├── registry.md                        # Single source of truth for lifecycle
├── CLAUDE.md                          # (this file)
├── test.md                            # Acceptance criteria for this harness
├── .claude/
│   ├── settings.json                  # Permissions + Stop hook wiring
│   ├── hooks/qa-gate.sh               # Stop hook — hygiene checks
│   └── agents/                        # Agent definitions
├── .harness/
│   ├── progress.tsv                   # Append-only, schema: timestamp/project/phase/status/disk_mb/duration_sec/notes
│   ├── ports.tsv                      # Port allocations (no collisions)
│   ├── secrets-map.md                 # bws project x secret x consumer
│   ├── scorecard-template.md          # Shared 8-dimension rubric
│   ├── reverify-schedule.tsv          # When each project is due for re-verify
│   ├── experience/
│   │   ├── patterns.md                # What works across projects
│   │   ├── failures.md                # What breaks + the fix
│   │   ├── playbooks.md               # Install recipes per runtime
│   │   └── runtimes.md                # Toolchain versions observed
│   ├── templates/                     # .envrc, .tool-versions, plan.md, decisions.md, data-touched.md
│   └── reports/                       # Per-audit / comparison / digest outputs
├── scripts/
│   ├── reverify.sh                    # Re-run verification for a project
│   ├── archive.sh                     # Move deprecated → _archive/
│   ├── upstream-digest.sh             # GitHub releases since last_verified
│   ├── similarity-check.sh            # Pre-install overlap detection
│   ├── port-registry.sh               # List / claim / check ports
│   └── disk-audit.sh                  # Lab-wide footprint report
└── projects/
    ├── <name>/                        # Isolated per project
    │   ├── plan.md
    │   ├── decisions.md
    │   ├── data-touched.md
    │   ├── setup-log.md
    │   ├── qa-report.md
    │   ├── reverify-<YYYYMMDD>.md     # One per re-verify pass
    │   └── <cloned-repo>/             # .envrc + .tool-versions live here
    ├── _archive/                      # Archived projects (read-only)
    └── _scouting/<category>/          # Candidate comparisons before install
```

## Hard rules

- **Isolation**: every project gets its own folder. State dirs under `~/.<name>/` are recorded in `setup-log.md` → `State Locations` and respected at uninstall. Per-project `.envrc` + `.tool-versions` are the preferred isolation mechanism.
- **Registry is sacred**: every install / lifecycle change updates `registry.md` + appends `progress.tsv`. The Stop hook warns if drift is detected.
- **Secrets 管理**: 不在文件中明文存储 secrets。推荐 `bws`（Bitwarden Secrets Manager）：`bws run --project-id <uuid> -- <cmd>`。如果没有 bws，可以用项目级 `.env` 文件（加入 `.gitignore`）或系统 Keychain。无论哪种方式，在 `.harness/secrets-map.md` 中记录每个 secret 的用途和存放位置。
- **QA is independent**: @qa has no Edit tool. If a fix is needed, it messages @executor with repro steps; it does not fix.
- **UX feedback is mandatory**: every QA pass asks 2-3 action-triggering questions.
- **Minimal config**: default to simplest working setup; add complexity only on user request.
- **Ceremony scales with risk**: a plan.md one-liner is fine for trivial tools; full ceremony for anything touching personal data or system state.

## Workflow triggers

| User input | Flow |
|---|---|
| Repo URL or `owner/name` | 1. similarity-check → 2. @planner → 3. approve plan → 4. @executor → 5. @qa → 6. update registry |
| Category name ("AI X") | 1. @scout → 2. user picks → 3. as above |
| "Compare A and B" | 1. @comparator → 2. read report |
| "Re-verify <name>" | 1. @curator → 2. scripts/reverify.sh |
| "Archive <name>" | 1. @curator sets deprecated → 2. after confirmation, scripts/archive.sh |
| "What's new upstream?" | scripts/upstream-digest.sh |
| "Lab health?" | scripts/disk-audit.sh + registry sweep |

## Conventions

- **Node / Bun / Python**: prefer mise (`.tool-versions`) over system toolchain. `brew upgrade` should not silently break projects.
- **Ports**: claim via `scripts/port-registry.sh claim <name> <port>`. 8080-8999 is the lab range.
- **Secrets**: named like `UPSTREAM_REQUIRED_NAME` in bws; remap on fetch if needed.
- **Every setup-log must have**:
  - State Locations (code + state + binary)
  - Verification ladder (checked checkboxes)
  - Uninstall Command (copy-pasteable)
  - Deviations From Plan
- **Reports rot fast**: scouting reports expire in ~6 months; scorecards should be re-run if >90 days old and the project is being compared.

## Stop hook (hygiene)

`.claude/hooks/qa-gate.sh` runs after every response. It warns on:
- Project folder without a registry row
- Installed project without `setup-log.md`
- Port collisions in `ports.tsv`
- Stale projects (>90 days since re-verify)
- progress.tsv schema mismatch

Non-fatal — warnings show up prefixed `::lab-gate::` in Claude's next turn.

## Acceptance

See `test.md` for the checklist this harness itself must pass. If a change breaks a test.md item, the change isn't done.
