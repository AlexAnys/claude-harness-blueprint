# Patterns

Accumulated learnings from real project installs.
Every row is traceable to a concrete `projects/<name>/setup-log.md`.

## Install idiom by runtime

| Runtime | Typical install shape | Example | Source |
|---|---|---|---|
| **Node.js + npm** | `git clone → npm i → edit config → npx <cmd> build --serve` | <project-a> | `projects/<project-a>/setup-log.md` |
| **Bun** | `bun install → bun link` (NEVER `bun install -g`) + first-run `init`/`doctor` | <project-b> | `projects/<project-b>/setup-log.md` |
| **Python** | `uv venv --python X.Y → source venv/bin/activate → uv pip install -e ".[all]"` | <project-c> | `projects/<project-c>/plan.md` |
| **curl-pipe-bash installer** | Vendor-provided `install.sh` writes to `~/.<tool>/` + symlinks into `~/.local/bin/` | <project-c> | `projects/<project-c>/plan.md` |

## Smoke-test ladder (in this order, each is cheap)

1. **Binary on PATH** — `<cmd> --version` returns something
2. **Config sane** — `<cmd> doctor --json` / `<cmd> check` passes (or warns predictably)
3. **Empty init** — `<cmd> init` creates state dir; record exact location
4. **Tiny input** — feed 10-20 files / one URL; watch for error classes, not counts
5. **Real workload** — only after 1-4 pass

This ladder caught all projects' issues early; skipping steps costs hours.

## Secrets injection (standard pattern)

- Bitwarden Secrets Manager (bws) is the single source of truth.
- The `bws` access token itself lives in macOS Keychain (service name: `bws`).
- `~/.zshrc` bootstraps `BWS_ACCESS_TOKEN` from Keychain at interactive-shell start.
- Per-tool wrappers inject secrets at call time via `bws run --project-id <bws-project-id> -- <tool>`.
- **Remap-on-fetch** when the upstream tool expects an env var name different from the secret's name in bws.

## State-directory conventions

Most projects put runtime state in `~/.<name>/`, NOT in `projects/<name>/`. This is a source of hidden coupling — the lab thinks projects are isolated; they aren't.

| Project | Code lives | State lives | Isolated? |
|---|---|---|---|
| <project-a> (Node SSG) | `projects/<project-a>/<repo>/` | in-tree (`content/`, `public/`) | yes |
| <project-b> (Bun CLI) | `projects/<project-b>/repo/` | `~/.<project-b>/` (PGLite) | no — global |
| <project-c> (Python agent) | `~/.<project-c>/<repo>/` | `~/.<project-c>/` | no — global (code + state) |

**Rule**: record state location in each `setup-log.md` under a `State Locations` section. Backup and uninstall must reference this explicitly.

## Port allocation

Projects with web servers should reserve a port. See `.harness/ports.tsv`.

New projects MUST claim a port in `ports.tsv` before starting a server; no overlap.

## Bash-tool vs interactive-shell gotcha (ALWAYS hits)

`~/.zshrc` is NOT sourced in Bash-tool subshells. Anything that relies on aliases, functions, or exports defined there will silently fail. Workarounds:

- Load from Keychain inline: `export BWS_ACCESS_TOKEN="$(security find-generic-password -a "$(whoami)" -s "bws" -w 2>/dev/null)"`
- Use `command <name>` to bypass shell-function wrappers
- When testing, verify the env is what the Bash tool sees, not what a login shell sees

Record this in `.harness/experience/failures.md` every time a new project trips over it.

## Content-import failure classes (generalizable)

Observed in projects importing non-ASCII content:

| Class | Cause | Fix |
|---|---|---|
| Empty slug | non-ASCII filenames slugify to `""` | rename or patch slugify to fall back to UUID |
| Path traversal | `/` or `..` in title | sanitize before slug |
| Encoding | BOM, CRLF | normalize at ingest |

Any project that ingests user files should be tested with: ASCII-only, CJK, emoji, space-in-name, `../`, empty file, 10MB file. Write these test cases once per ingest-capable project.

## Config-file styles

| Style | Used by | Edit ceremony |
|---|---|---|
| `.env` (KEY=VALUE) | many tools | easy, merges cleanly |
| YAML | config-heavy tools | watch indentation |
| TypeScript (`.config.ts`) | build tools | re-runs TS on every build |
| JSON | generic | no comments, strict |
| CLI-managed (`<cmd> config set`) | many tools | safest; reaches into secrets |

Prefer CLI-managed > .env > YAML > JSON > TS-config, when the choice exists.

## Verification that caught real bugs

- **`curl -s localhost:<port> | head -20`** caught baseUrl malformation in an SSG project
- **`<cmd> doctor --json | jq '.checks[] | select(.status!="ok")'`** caught bws injection missing
- Any tool with a `doctor` subcommand is a good citizen; note it in the plan

## Project-type shapes (for future scout + comparator)

Three shapes seen so far:

1. **Static site generator** — input: markdown, output: HTML, verify: browser
2. **Headless service + CLI** — input: markdown/API, output: queries, verify: CLI + maybe MCP
3. **Interactive agent / TUI** — input: chat, output: actions, verify: manual interaction + TUI screenshot

These three map to three different QA strategies. Don't let the "verify with curl" habit from SSGs leak into agent/TUI verification.
