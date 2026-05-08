# Playbooks

Reusable install / verify / uninstall sequences by project shape.
Executor should pick a playbook first, then adapt — don't start from scratch.

---

## Playbook A: Node SSG / CLI (quartz-shape)

**Signals**: README says Node v22+, package.json present, `npm start` / `npx <cmd>` entry points.

### Install
```bash
cd projects/<name>/
git clone <repo-url> <name>
cd <name>
node --version && npm --version          # capture in setup-log
npm i
```

### Configure
- Edit config file (TS / JS / JSON).
- Minimum changes only: title, baseUrl, locale, analytics → null.

### Verify
```bash
npx <cmd> build                           # sanity
npx <cmd> build --serve &                 # background
curl -s http://localhost:<port> | head -5 # HTTP 200?
```

### Uninstall
```bash
rm -rf projects/<name>/<name>
# No system state to clean
```

---

## Playbook B: Bun CLI + local DB (gbrain-shape)

**Signals**: README requires Bun, CLI tool, local embedded DB (PGLite / SQLite), MCP server mode.

### Install
```bash
# Bun must be present system-wide
bun --version || curl -fsSL https://bun.sh/install | bash
cd projects/<name>/
git clone <repo-url> repo
cd repo
bun install
bun link          # NEVER `bun install -g` — breaks postinstall migrations
command <name> --version
```

### Configure
- Secrets: add to your bws project; install shell wrapper (see the first Bun CLI project's `setup-bws.sh` as reference).
- NEVER edit `~/.zshrc` directly from a session; use a reviewable script.

### Verify
```bash
# Bash tool: load bws token inline (zshrc doesn't source here)
export BWS_ACCESS_TOKEN="$(security find-generic-password -a "$(whoami)" -s "bws" -w 2>/dev/null)"
bws run --project-id <id> -- <name> doctor --json | jq '.status,.health_score'
bws run --project-id <id> -- <name> init
# Tiny smoke test
bws run --project-id <id> -- <name> import ~/some-test-folder/ --no-embed
```

### Uninstall
```bash
rm -rf ~/.<name>/                         # ← CRITICAL: state dir, verify path from setup-log
rm -rf projects/<name>/repo
# Optional: remove bws wrapper lines from ~/.zshrc
```

---

## Playbook C: Python agent with TUI (hermes-shape)

**Signals**: pyproject.toml, Python 3.11 pinned, installer script, TUI entry.

### Install (vendor installer path — preferred)
```bash
curl -fsSL <installer-url> | bash
source ~/.zshrc
<name> doctor
<name> setup       # interactive wizard — requires user decisions
```

### Install (dev path — for hacking on the source)
```bash
cd projects/<name>/
git clone <repo-url> repo
cd repo
curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv venv --python 3.11
source venv/bin/activate
uv pip install -e ".[all,dev]"
python -m pytest tests/ -q
```

### Verify
- `<name> doctor` exits clean
- Launch TUI, send one trivial prompt, confirm response
- Invoke one tool (web search, file list) — verify tool-use path

### Uninstall
```bash
rm -rf ~/.<name>/                         # residual profile data; explicit required
rm -f ~/.local/bin/<name>                 # symlink
rm -rf projects/<name>/repo
```

---

## Common post-install steps (all playbooks)

1. **Record state location** in `setup-log.md` under `## State Locations` (code dir + data dir + binary symlink).
2. **Claim port** in `.harness/ports.tsv` if the project runs a server.
3. **Fill `decisions.md`** with the 2-3 choices the planner flagged and what was chosen.
4. **Update registry.md** — lifecycle = `installed`, last_verified = today.
5. **Append `progress.tsv`** — one row per phase.
6. **Run `scripts/reverify.sh <name>`** to confirm the install is reproducible from `setup-log.md`.

---

## Playbook D: Docker Compose self-host server stack + Homebrew CLI/daemon (multica-shape)

**Signals**: Two-tier — server stack (Postgres + Go backend + Next.js frontend) shipped via `docker-compose.selfhost.yml`; CLI + daemon shipped as a separate Homebrew tap; daemon polls server for tasks and spawns external CLIs (claude, codex, …) on the host PATH.

### Pre-flight (mandatory)
```bash
# 1) Doctor-check Docker BEFORE anything else
which docker && docker --version && docker compose version
# Any failure → halt; do not auto-install Docker Desktop. User must choose engine.

# 2) Port collision audit for every published port the compose file declares
for p in 3000 8080 5432; do lsof -nP -i :$p -sTCP:LISTEN | head -3; done
# Each occupied port → remap via .env env-var (compose typically supports ${PORT:-default})
```

### Install
```bash
cd projects/<name>/
git clone --depth 1 <repo-url> repo
cd repo
cp .env.example .env

# Patch .env (sed -i '' on macOS)
JWT=$(openssl rand -hex 32) && sed -i '' "s|^JWT_SECRET=.*|JWT_SECRET=${JWT}|" .env
sed -i '' "s|^APP_ENV=.*|APP_ENV=development|" .env  # iff dev master code is needed AND deployment is 127.0.0.1-only
# Apply any port remaps the audit revealed

# Public-image pull (no creds needed for GHCR public)
# If credstore symlinks are dangling: temporarily replace ~/.docker/config.json with {"auths":{}} (back it up first)
docker compose -f docker-compose.selfhost.yml pull
docker compose -f docker-compose.selfhost.yml up -d

# CLI
brew install <tap>/<name>
<name> config set server_url http://localhost:<backend_port>
<name> config set app_url    http://localhost:<frontend_port>
```

### Authenticate (non-interactive shortcut for local dev)
Browser-flow `<name> login` blocks on user click-through. For executor / CI use, drive the API directly when the upstream supports it:
```bash
# 1) email + master code → JWT
curl -sS -X POST http://localhost:<backend>/auth/send-code   -H 'Content-Type: application/json' -d "{\"email\":\"$EMAIL\"}"
JWT=$(curl -sS -X POST http://localhost:<backend>/auth/verify-code -H 'Content-Type: application/json' -d "{\"email\":\"$EMAIL\",\"code\":\"888888\"}" | jq -r .token)
# 2) create workspace
curl -sS -H "Authorization: Bearer $JWT" -H 'Content-Type: application/json' -X POST http://localhost:<backend>/api/workspaces -d '{"name":"Lab","slug":"lab"}'
# 3) mint PAT (the prefixed format the CLI expects, NOT the /api/cli-token JWT)
PAT=$(curl -sS -H "Authorization: Bearer $JWT" -H 'Content-Type: application/json' -X POST http://localhost:<backend>/api/tokens -d '{"name":"lab-cli","expires_in_days":90}' | jq -r .token)
echo "$PAT" | <name> login --token
```

### Daemon + agent
```bash
<name> daemon start
<name> daemon status                   # confirm "running" + agents detected
<name> agent create --workspace-id <ws> --name "Claude (lab)" --runtime-id <claude-runtime-id>
<name> issue create --workspace-id <ws> --title "smoke" --description "..." --assignee "Claude (lab)"
# Poll runs until completed_at is non-null (use `until`/sleep loop)
```

### Verify (smoke ladder)
- [ ] `docker compose ps` — all 3 services healthy
- [ ] `curl http://localhost:<backend>/health` → `{"status":"ok"}` *(grep router source for actual path; do NOT trust READMEs)*
- [ ] `curl http://localhost:<frontend>` → 200
- [ ] `<name> auth status` shows logged-in user + correct server URL
- [ ] `<name> daemon status --output json | jq .status` = `"running"`
- [ ] `curl http://127.0.0.1:<daemon-port>/health` returns daemon JSON (path varies — try `/health` first)
- [ ] At least one agent runtime appears `online` in `<name> runtime list`
- [ ] End-to-end: smoke issue → daemon claims (typically <5 s) → agent CLI spawns → status `completed`

### Uninstall
```bash
<name> daemon stop
cd projects/<name>/repo
docker compose -f docker-compose.selfhost.yml down -v --remove-orphans
brew uninstall <name>
brew untap <tap>
rm -rf ~/.<name>/                       # CLI config + daemon log + PAT
rm -rf ~/<name>_workspaces/             # agent task workdirs (if upstream uses this)
rm -rf projects/<name>/repo
# (optionally) docker image rm of the 3 pulled images
```

### Watch-outs
- **Pre-existing Docker workloads on host** (other compose stacks, dev Postgres, etc.) WILL collide — do the `lsof` audit, don't trust defaults.
- **`APP_ENV=development` master code** turns the instance into "anyone with email + 888888 = admin". Only acceptable on 127.0.0.1; setup-log MUST carry a security banner if dev mode is on.
- **Daemon spawns agent CLIs with bypassed permissions** — workdir is scoped per task but tool calls are not gated. Document this; it's the major attack surface.
- **CLI `--token` flag expects upstream's PAT format** (e.g. `<prefix>_<hex>`); session JWTs from `/api/cli-token`-style endpoints will be rejected.
- **OrbStack / Docker Desktop migration footguns** — see `failures.md` for the dangling-symlink class of failures.

---

## Playbook E: Build-from-scratch local-first overlay app (pando-shape)

**Signals**: NOT a clone-and-install. User wants a new app scaffolded from scratch. Lifecycle = `planning` → `building` → `installed` (after Phase 0 spike PASS), not direct to `installed`. Multi-language monorepo (Next.js web + Go daemon + TS shared packages). Reads + writes a Markdown vault (Obsidian-compatible). Spawns local CLI agents (`claude` / `codex`) per-task in isolated workdirs.

### Pre-flight (mandatory)
```bash
node --version          # v22+ required
pnpm --version          # v9+ required
go version              # 1.22+ required
sqlite3 --version       # 3.40+ required (system / brew)
which claude codex gh   # all three must resolve
gh auth status          # must be logged in to the target GitHub account

# Vault path & state path: confirm both writable before scaffold; create as mode 700.
# Port collision audit for the dev ports the new app will bind:
for p in <web_port> <broker_port>; do lsof -nP -i :$p -sTCP:LISTEN | head -3; done
```

### Install (scaffold, not clone)
```bash
cd projects/<name>/
mkdir -p repo && cd repo
git init -b main

# Root pnpm workspace
cat > package.json <<'JSON'
{
  "name": "<name>-monorepo",
  "private": true,
  "packageManager": "pnpm@10.30.1",
  "engines": { "node": ">=22" },
  "scripts": {
    "typecheck": "pnpm -r run typecheck",
    "test": "pnpm -r run test",
    "dev:web": "pnpm --filter @<name>/web dev",
    "dev:broker": "cd apps/broker && go run ./cmd/broker"
  }
}
JSON
cat > pnpm-workspace.yaml <<'YAML'
packages:
  - "apps/*"
  - "packages/*"
YAML

# Initial scaffold commit BEFORE creating the GitHub remote
git add . && git commit -m "chore: initial scaffold"

# GitHub repo (private — adapt visibility per project)
gh repo create <user>/<name> --private --source . --push

# Next.js 16 web app (note flags — avoid prompts)
mkdir -p apps/web && cd apps/web
pnpm dlx create-next-app@latest . --ts --eslint --tailwind --app --src-dir \
  --import-alias "@/*" --no-turbopack --use-pnpm --skip-install --yes
# Then `rm pnpm-workspace.yaml` (create-next-app drops one inside; root has it)
# Edit name to "@<name>/web", lock dev port via "next dev -p <web_port>"

# Go daemon
cd ../broker
go mod init github.com/<user>/<name>/broker
# layout: cmd/<name>/main.go + internal/{agents,runner,cognitive,vaultlog,config}
# (see your first build-from-scratch project's apps/broker for the reference)

# Shared TS packages — schema, vault, indexer
# Each: package.json (workspace:* deps + zod / better-sqlite3 / gray-matter as needed)
#       tsconfig.json (target ES2022, module ESNext, moduleResolution Bundler, strict)
#       src/index.ts + src/index.test.ts
#       vitest.config.ts

# Vault + state dirs
mkdir -p <vault_path>/{directions/seed,artifacts,tasks,daily,.evolution/{events,schema}}
chmod 700 <vault_path>
mkdir -p ~/.<name>/{workspaces,logs}
chmod 700 ~/.<name>

# Project-local pins
cat > ../../.tool-versions <<EOF
nodejs <pinned-node>
go <pinned-go>
EOF
cat > ../../.envrc <<EOF
export <NAME>_VAULT="<vault_path>"
export <NAME>_HOME="\$HOME/.<name>"
EOF
```

### Phase 0 spike (hard gate before Phase 1 work)
1. **Spike A** — Daemon `doctor` returns CLI agents (paths + versions) with `available:true`, plus `vault:exists+writable` and `seed_notes` count.
2. **Spike B** — Daemon `run` spawns CLI in per-task `~/.<name>/workspaces/<run-id>/workdir/`, captures stdout/stderr to `<vault>/.evolution/events/YYYY-MM.jsonl`, exits 0.
3. **Spike C** — Markdown writer produces YAML-frontmatter notes with `[[wikilinks]]` resolvable in Obsidian. Write a synthetic Direction + Artifact and verify the link to seed notes resolves.
4. **Spike D** — SQLite indexer parses the vault, populates tables, idempotent drop+rebuild.
5. **Spike E** — CLI-driven structured-output parse-success rate over ~20 calls. Threshold (e.g. 80%) must be met or escalate the cognitive-cost decision.

### Verify (smoke ladder for the BUILT app)
- [ ] `node --version`, `go version`, `pnpm --version`, `claude --version`, `codex --version`, `gh auth status` all succeed
- [ ] `gh repo view <user>/<name> --json visibility,url` returns `private` (or as locked)
- [ ] `git remote -v` shows `origin = git@github.com:<user>/<name>.git` (or HTTPS)
- [ ] `pnpm install && pnpm -r run typecheck && pnpm -r run test` — all green
- [ ] `cd apps/<name> && go build ./... && go test ./...` — zero failures
- [ ] `<name>-broker doctor --json` returns `healthy:true` with all agents `available:true`
- [ ] Tiny smoke run via `<name>-broker run` exits 0 with the expected stdout
- [ ] `<name>-broker spike-e --count 20 --threshold 0.8` PASS
- [ ] `pnpm dev:web` listens at `http://localhost:<web_port>`; every scaffold route returns HTTP 200
- [ ] Open the vault in Obsidian; wikilinks from synthetic Direction → seed notes resolve

### Uninstall
```bash
# Daemon + dev servers down
pkill -f '<name>-broker serve' || true
# Drop SQLite cache + event log inside the vault (vault content PRESERVED)
rm -rf "<vault_path>/.evolution/index.sqlite"
rm -rf "<vault_path>/.evolution/events"
# Drop daemon state + workspaces
rm -rf ~/.<name>/
# Remove the lab repo
rm -rf projects/<name>/repo
# Optional: delete the entire vault — only if user explicitly chooses
# rm -rf <vault_path>
# Optional: delete the GitHub repo
# gh repo delete <user>/<name> --confirm
# Free port claims
sed -i '' "/^<name>\t/d" .harness/ports.tsv
```

### Watch-outs
- **CLI flag drift, every release**: `claude --help` and `codex --help` change between releases. Adapter code MUST be derived from the live `--help` output, never from plan.md or upstream docs. Recorded in failures.md (codex `--output-format` doesn't exist; uses `--json` and `--output-last-message`).
- **Native modules vs. fast-moving Node**: avoid `better-sqlite3` on Node 25+ (no prebuilds; node-gyp + Python 3.14 host blocked us). Use built-in `node:sqlite` (stable in Node 25; experimental in 22).
- **Vitest with `node:` builtins**: vitest 1.x's vite resolver strips the `node:` prefix and fails. Upgrade to vitest 3.x.
- **Structured output field-key drift**: claude CLI 2.1+ with `--output-format json --json-schema <S>` puts the validated output in `structured_output`, not `result`. Always log raw stdout + parsed-into-domain-type for the first 5+ Spike-E calls until you've confirmed the field shape.
- **Codex needs `--skip-git-repo-check`**: codex 0.125.0 refuses to run outside a git repo by default; per-task workdirs are intentionally non-git.
- **Spike E cost transparency vs. billing**: each `claude --output-format json` call shows `total_cost_usd` in the envelope. On Pro/Max plans this rides the subscription — informational not separately billed. On API-key auth, this is real $.
- **Vault frontmatter contract**: the indexer is strict — every markdown file in `directions/` and `artifacts/` must have `id` + `title` + `created_at` + `updated_at` (and `direction_wikilink` + `run_id` + `provider` + `exit_code` + `started_at` + `finished_at` for artifacts). Seed-note copies that lack frontmatter must have one prepended at install time, not parsed-as-is.
- **Broker permission mode**: default to `default` (claude's safest); `bypassPermissions` is opt-in per task with explicit user flag. Broker should NOT hardcode bypassPermissions — that's the "blast radius" antipattern.

### Reference implementation
- Your first build-from-scratch project's `repo/` directory serves as the reference. apps/broker layout, packages/{schema,vault,indexer} structure, Spike A-E harness all live there.
- That project's `setup-log.md` has the full step-by-step log including all the gotchas above as they were encountered.

---

## When no playbook fits

If the project doesn't match A / B / C / D / E:

1. Scout fills a new shape description in `patterns.md` → `Project-type shapes`.
2. Planner drafts the install sequence following the Smoke-test ladder (pattern in `patterns.md`).
3. After install, back-write a Playbook F / … here.

Keep playbooks short. If one starts exceeding ~30 lines of commands, the project probably needs its own setup script (a `setup-<thing>.sh` in the project folder is the model).
