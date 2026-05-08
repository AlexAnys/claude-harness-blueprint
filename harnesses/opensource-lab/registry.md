# Open Source Lab Registry

Single source of truth for lab lifecycle. Every project here has a folder under `projects/` (or `projects/_archive/` if archived). Stop hook warns if this file drifts from disk.

**Lifecycle**: `scouting` → `planning` → `building` → `installed` → `adopted` → `deprecated` → `archived`

## Active

| # | Project | Repo | Category | Lifecycle | Installed | Last verified | Playbook | Scorecard | Port | Notes |
|---|---------|------|----------|-----------|-----------|---------------|----------|-----------|------|-------|

## Archived

_(none yet — see `projects/_archive/` if populated)_

## Scouting in progress

_(none — see `projects/_scouting/` for category-level candidate lists)_

## Schema

- **Lifecycle**:
  - `scouting` — under `_scouting/`, choosing among candidates
  - `planning` — plan.md exists, not yet installed
  - `building` — for build-from-scratch projects (Playbook E shape). Scaffold + Phase 0 spike in progress. Transition to `installed` on Phase 0 PASS + QA PASS + user approval.
  - `installed` — working in lab, re-verify monthly
  - `adopted` — used in daily workflow, re-verify weekly
  - `deprecated` — flagged, 30-day archive countdown
  - `archived` — moved to `projects/_archive/`, read-only
- **Playbook**: A / B / C / D / E / custom — see `.harness/experience/playbooks.md`
- **Port**: space-separated list; must match `.harness/ports.tsv`
- **Last verified**: YYYY-MM-DD of most recent @qa or @curator re-verify pass

## Update rules

- **@coordinator** adds rows after install; updates lifecycle on promotion.
- **@executor** flips `planning → building` at scaffold start (build-from-scratch projects only).
- **@coordinator** flips `building → installed` after Phase 0 PASS + QA PASS + user approval.
- **@curator** updates `Last verified` on each re-verify pass.
- **@scout** does NOT add rows here — scouting candidates live under `_scouting/`.
- **Stop hook** warns if any `projects/<name>/` folder is missing from the Active or Archived tables.
