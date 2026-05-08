# Runtimes

Toolchain reality across installed projects. Updated after every install.

## System baseline (as of 2026-04-22)

| Tool | Version | Path | Installed via |
|---|---|---|---|
| node | v25.5.0 | `/opt/homebrew/bin/node` | Homebrew |
| npm | 11.8.0 | (alongside node) | Homebrew |
| bun | 1.3.9 | `/opt/homebrew/bin/bun` | Homebrew |
| python3 | system | `/usr/bin/python3` | macOS |
| uv | (on demand) | `~/.local/bin/uv` | astral install script |
| git | 2.50.1 | `/usr/bin/git` | Xcode CLT |
| bws | 2.0.0 | `<your-path>/bin/bws` | brew (bitwarden/tap/bws) |

## Per-project pinned requirements

| Project | Runtime | Version constraint | Notes |
|---|---|---|---|
| quartz | Node | v22+ | System v25 fine |
| gbrain | Bun | any recent (1.x) | `bun link`, NOT `bun install -g` |
| hermes | Python | **3.11 only** (hard pin, not 3.12+) | uv downloads 3.11 auto |
| hermes | Node | v22 LTS (for Playwright) | installer puts it in `~/.hermes/node/` so it can differ from system v25 |

## Risk: system Node version drift

Homebrew will one day ship Node v26/v27. Some projects pin `<= vNN`. Without per-project isolation (see Phase C1 — `.tool-versions`), `brew upgrade` can break multiple projects at once.

**Mitigation plan**: each project with a version constraint writes `projects/<name>/.tool-versions` (mise/asdf format). Executor runs commands from inside that directory so the constraint activates automatically — if mise/asdf is installed.

## Install-time quirks, per runtime

### Node / npm
- `npm audit` noise is common; log it but don't fix for local dev.
- `npx <cmd>` re-downloads on every invocation unless the project has a local bin.

### Bun
- `~/.bun/bin` is where `bun link` lands symlinks — make sure PATH picks it up.
- Bash-tool subshells: may not have `~/.bun/bin` on PATH. Prepend explicitly if needed.
- Never `bun install -g` for anything with postinstall hooks (migrations, symlinks).

### Python / uv
- Always `uv venv` inside the project dir; never install into system Python.
- `.[all]` installs every extra — can be slow (~minutes) but gives full functionality.
- uv is self-updating; record its version once per session, don't fight it.

### curl-pipe-bash installers
- Always `cat` (or at least `curl | tee /tmp/install.sh && less /tmp/install.sh`) before piping to bash for any new vendor.
- Installers commonly assume `~/.local/bin` is on PATH. Verify.
- Track what directories the installer creates — you'll need them for uninstall.

## Reported by `--version` vs actual

Trust `<cmd> --version` over human documentation. Tools lie about themselves in READMEs more than in `--version`.
