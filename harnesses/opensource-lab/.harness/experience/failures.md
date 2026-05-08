# Failures

What went wrong and why during project explorations.
Each row must cite a project + file + a one-line fix.

## Shell / environment

| Date | Project | Failure | Root cause | Fix |
|---|---|---|---|---|
| — | <project-b> | `<cmd> doctor` said "Missing access token" | `~/.zshrc` not sourced in Bash-tool subshell → `BWS_ACCESS_TOKEN` unset | Load inline from Keychain: `export BWS_ACCESS_TOKEN="$(security find-generic-password -a "$(whoami)" -s "bws" -w 2>/dev/null)"` |
| — | <project-b> | `<cmd> init --help` started real init instead of printing help | CLI doesn't recognize `--help` on subcommand, falls through to default args | Always check a tool's actual help pattern (`<cmd> help <sub>` vs `<cmd> <sub> --help`) before assuming |

## Package manager

| Date | Project | Failure | Root cause | Fix |
|---|---|---|---|---|
| — | <project-b> | README-documented gotcha: `bun install -g <pkg>` silently breaks migrations | Global install skips postinstall hook that runs schema migrations | Use `bun link` from cloned repo; never `bun install -g` for this class of tool |
| — | <project-a> | 8 vulnerabilities (2 moderate / 6 high) reported by npm audit | Upstream transitive deps; common for SSGs | Not blocking for local dev; document but don't fix unless deploying publicly |
| — | <project-d> | `docker compose pull` failed: `error getting credentials - err: exec: "docker-credential-osxkeychain": executable file not found in $PATH` | OrbStack uninstall left `/usr/local/bin/docker-credential-{osxkeychain,desktop}` as dangling symlinks pointing into removed OrbStack paths | (1) Public images: temporarily remove `"credsStore": "osxkeychain"` from `~/.docker/config.json` (back it up first). (2) Long term: `sudo ln -sf /Applications/Docker.app/Contents/Resources/bin/docker-credential-osxkeychain /usr/local/bin/docker-credential-osxkeychain` |
| — | <project-e> | `pnpm install` warned `Ignored build scripts: better-sqlite3, esbuild, sharp, unrs-resolver`. After approving via `pnpm.onlyBuiltDependencies`, `better-sqlite3` still failed to compile from source on Node 25 + Python 3.14 (no prebuilt binary; node-gyp `make` failed with `_XML_SetAllocTrackerActivationThreshold` mismatch in Python 3.14's `pyexpat`) | Switched the indexer to Node's built-in `node:sqlite` (stable in Node 25; experimental in 22). Removed `better-sqlite3` dep. Required `@types/node@^22.10` for typings + `vitest@^3` so vitest's vite resolver doesn't strip the `node:` prefix. |

## Content / import

| Date | Project | Failure | Root cause | Fix |
|---|---|---|---|---|
| — | <project-b> | 12 files of Chinese-filename vault failed import with `Invalid slug: ""` | Slugify falls back to empty string when filename has only non-ASCII chars | Upstream bug; workaround = rename or pre-slug |
| — | <project-e> | Indexer tried to index seed-note copies but they had no YAML frontmatter (raw markdown copies). Indexer raised `missing required frontmatter key "id"`. | Plan copied notes verbatim; they were never structured as the app's domain objects. | At install time, prepend a small frontmatter header (`id`, `title`, `status`, `created_at`, `updated_at`, `parents:[]`, `tags:[seed,anchor]`) to each seed copy before the original body. Now indexable AND original content preserved. |

## Runtime / version

| Date | Project | Failure | Root cause | Fix |
|---|---|---|---|---|
| planned | <project-c> | Will not run on Python 3.12+ | Project pins 3.11 (installer downloads 3.11 via uv if host has 3.12+) | Use uv-managed Python 3.11, not system Python |
| known | <project-c> | Ollama on macOS returns HTTP 503 | Upstream issue | Use OpenRouter or switch LLM provider |

## CLI flag drift (trust the code, not the docs)

| Date | Project | Failure | Root cause | Fix |
|---|---|---|---|---|
| — | <project-d> | Plan said health endpoint was `/api/health`; got 404 | Planner trusted README/intuition; actual route in router source is `/health` | Always grep router source for actual paths before claiming success criteria. Pattern: trust the code, not the docs. |
| — | <project-e> | `codex exec --output-format json <prompt>` failed: codex CLI has no `--output-format` flag. It uses `--json` (JSONL events) and `--output-last-message <FILE>`. | Plan was authored from intuition; actual `codex exec --help` lists different flags. | Use `--skip-git-repo-check` for non-git workdirs. For structured output, prefer claude `--output-format json --json-schema <schema>`. |
| — | <project-e> | Run failed: `codex exec` exit 1, stderr `Not inside a trusted directory and --skip-git-repo-check was not specified.` | codex default-refuses to run outside a git repo (per-task workdirs are intentionally non-git). | Always pass `--skip-git-repo-check` when invoking `codex exec` from per-task workdirs. |
| — | <project-e> | 0/3 parses succeeded. Stdout had `"result": ""` but a populated `"structured_output": {...}` field. The extractor only read `result`. | claude CLI with `--output-format json --json-schema <S>` puts the validated structured output in `structured_output` (and `result` is empty). | Updated extractor to try `structured_output` first, fall back to `result`. Re-run: 20/20 = 100% parse rate. |

## Framework / SSR boundary

| Date | Project | Failure | Root cause | Fix |
|---|---|---|---|---|
| — | <project-e> | SSR returned HTTP 500 with `Error: Only plain objects, and a few built-ins, can be passed to Client Components from Server Components. Classes or null prototypes are not supported.` | Node 25's built-in `node:sqlite` returns rows as objects with **null prototype**, not `Object.prototype`. Next.js 16 strict-checks the Server→Client Component boundary serialization and rejects null-prototype objects. | Added a `plain<T>()` helper that recursively shallow-clones into Object.prototype objects. Pattern applies to anything bridging `node:sqlite` → React. |

## State / disk

| Date | Project | Failure | Root cause | Fix |
|---|---|---|---|---|
| — | <project-b> | Assumed PGLite DB was a single file; backup docs lied | It's a PGDATA directory (~39 MB with WAL / base / global subdirs) | Backup = copy whole tree |
| standing | all | Global state dirs (`~/.<name>/`) break the "projects are isolated" assumption | Upstream convention, not something we chose | Record state dir in setup-log; isolation layer may symlink state back into `projects/<name>/state/` |
| — | <project-d> | Compose default ports silently collided with another running project | Plan didn't preflight `lsof -i :PORT`; assumed defaults were free | Always `lsof -nP -i :<port> -sTCP:LISTEN` for each compose-published port BEFORE `up -d`. Remap via `${PORT:-default}` env vars in `.env` if any occupied. |
| — | <project-d> | `<cmd> login --token` rejected JWT from session endpoint with "must start with <prefix>_" | Confused two real endpoints: one mints session JWT (for web/SDK), another mints a prefixed PAT (for CLI). Same auth, different formats. | Use the PAT-minting endpoint with `{name, expires_in_days}` to get the right format for CLI login. |
| — | <project-d> | Daemon hardcodes `--permission-mode bypassPermissions` when spawning CLI agent — agent has unrestricted tool access in its task workdir | Upstream design choice for autonomous task execution. Workdir IS scoped but tool calls themselves are not gated. | Document in setup-log security notes. For lab smoke testing acceptable; treat as red flag if scaling up. |
| — | OrbStack | `brew uninstall orbstack` does NOT clean `/usr/local/bin/docker*` symlinks it created during install | OrbStack hijacks docker symlinks, then leaves them dangling on uninstall — breaks any pre-existing Docker Desktop install | After OrbStack uninstall, re-link to Docker.app. Or just open Docker Desktop → Settings → Advanced → "Install command line tools". |

## Security

| Date | Project | Failure | Root cause | Fix |
|---|---|---|---|---|
| known | <project-c> | API server + webhook modes have unauthenticated RCE | Open upstream issues | Never expose the gateway publicly without auth; local CLI only |

## Harness infrastructure

| Date | Component | Failure | Root cause | Fix |
|---|---|---|---|---|
| — | coordinator | Install never started despite multiple rounds of dispatching executor + qa — silent failure across day boundary | `coordinator.md` had `TeamCreate` as Step 5, AFTER the plan-approval checkpoint. Plan checkpoint = blocking I/O = task termination. Coordinator died before reaching Step 5. Subsequent `Agent({subagent_type: "coordinator"})` calls = fresh short-lived subagents, each dying again at the same checkpoint. SendMessages went to dead inboxes. No error surfaced because nothing checked "is the team alive?" | Moved `TeamCreate` to **Step 0** (mandatory bootstrap before any user-facing work). Added top-of-CLAUDE.md "Bootstrap Protocol" hard rule for any entry point. Added `settings.json` `"agent": "coordinator"` so coordinator is the default. Added `qa-gate.sh` check #6b that warns if `plan.md` files exist but `~/.claude/teams/lab/` doesn't. Added `test.md` runtime acceptance items that exercise team persistence. |
| — | coordinator (recovery) | After fix above: spawned coordinator into lab team, its Step 0 immediately failed — "I don't have Agent or TeamCreate tools." | Claude Code platform strips `Agent` and `TeamCreate` from team-spawned agents regardless of frontmatter `tools:` declaration (likely to prevent recursive spawning). The original "coordinator spawns its own teammates" design assumes a tool the coordinator cannot have once spawned into a team. | Reframed responsibility: **team-lead spawns, coordinator dispatches**. Updated `coordinator.md` Step 0 to "verify members; if missing, SendMessage team-lead to spawn." Updated CLAUDE.md Bootstrap Protocol to make team-lead the spawning authority. |

## How to use this log

- After every project install, append rows for anything that surprised you.
- If a failure recurs across projects (e.g. the `~/.zshrc` one), promote it to `patterns.md` as a pattern to watch for proactively.
- Planner must read this file during research — it's the short list of "has this bitten us before?"
