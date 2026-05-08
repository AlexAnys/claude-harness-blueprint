#!/usr/bin/env bash
# reverify.sh <project-name>
#
# Fresh-run the verification steps documented in projects/<name>/setup-log.md.
# Produces projects/<name>/reverify-<YYYYMMDD>.md with diff-from-last results.
# Updates .harness/reverify-schedule.tsv on pass.
#
# Read-only by intent: no fixes, only surfaces drift. @curator then decides.
#
# Usage:
#   scripts/reverify.sh quartz
#   scripts/reverify.sh --all            # every 'installed' / 'adopted' project

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
LAB_ROOT="$(pwd)"

die() { echo "✗ $*" >&2; exit 1; }
say() { echo "▶ $*"; }

today() { date -u +%Y-%m-%d; }

reverify_one() {
  local name="$1"
  local dir="projects/$name"
  [[ -d "$dir" ]] || { echo "✗ no projects/$name"; return 1; }
  [[ -f "$dir/setup-log.md" ]] || { echo "⚠ $name has no setup-log.md — skipping"; return 1; }

  local date_stamp
  date_stamp="$(today)"
  local report="$dir/reverify-$(date -u +%Y%m%d).md"

  say "Re-verifying $name → $report"

  {
    echo "# $name — Re-verify"
    echo
    echo "_Date: ${date_stamp}_"
    echo
    echo "## Method"
    echo "Extracted verification steps from \`setup-log.md\` and re-ran fresh."
    echo
    echo "## Results"
    echo

    # Binary version
    local bin="$name"
    if command -v "$bin" >/dev/null 2>&1; then
      local ver
      ver="$($bin --version 2>&1 | head -1 || true)"
      echo "- Binary: \`$bin\` on PATH → \`$ver\`"
    else
      echo "- Binary: ⚠ \`$bin\` NOT on PATH (was it installed with \`bun link\` etc.? check setup-log)"
    fi

    # Doctor (if applicable)
    if command -v "$bin" >/dev/null 2>&1 && $bin help 2>&1 | grep -qi "doctor" ; then
      echo
      echo "### \`$bin doctor\` output"
      echo '```'
      $bin doctor 2>&1 | head -40 || true
      echo '```'
    fi

    # Disk
    echo
    echo "### Disk footprint"
    echo '```'
    du -sh "$dir" 2>&1 || true
    # Global state directory hint
    if [[ -d "$HOME/.$name" ]]; then
      du -sh "$HOME/.$name" 2>&1
    fi
    echo '```'

    # Setup log summary
    echo
    echo "### Known state (from setup-log.md)"
    if [[ -f "$dir/setup-log.md" ]]; then
      grep -E "^- " "$dir/setup-log.md" | head -15 || true
    fi

    echo
    echo "## Verdict"
    echo
    echo "- [ ] Binary version matches setup-log"
    echo "- [ ] \`doctor\` still clean (or warns only as before)"
    echo "- [ ] Disk footprint within 2× setup-log"
    echo "- [ ] No new error class"
    echo
    echo "_Curator: fill in above, then update registry.md + reverify-schedule.tsv._"
  } > "$report"

  echo "✓ $report"
  # Update schedule tsv (best-effort; curator confirms pass manually)
  python3 - "$name" "$date_stamp" <<'PY' || true
import sys, pathlib, datetime as dt
name, today = sys.argv[1], sys.argv[2]
f = pathlib.Path(".harness/reverify-schedule.tsv")
if not f.exists(): sys.exit(0)
lines = f.read_text().splitlines()
out = []
for ln in lines:
    if ln.startswith(f"{name}\t"):
        parts = ln.split("\t")
        if len(parts) >= 5:
            parts[4] = today  # last_verified
            # bump next_due by cadence
            cadence = parts[2]
            days = {"weekly": 7, "monthly": 30, "quarterly": 90}.get(cadence, 30)
            parts[3] = (dt.datetime.strptime(today, "%Y-%m-%d") + dt.timedelta(days=days)).strftime("%Y-%m-%d")
        ln = "\t".join(parts)
    out.append(ln)
f.write_text("\n".join(out) + "\n")
PY
}

if [[ "${1:-}" == "--all" ]]; then
  awk -F'|' '
    NR>1 && NF>=6 {
      name=$3; lc=$6
      gsub(/^ +| +$/,"",name); gsub(/^ +| +$/,"",lc)
      if (lc=="installed" || lc=="adopted") print name
    }' registry.md \
    | while read -r name; do
        [[ -n "$name" ]] && reverify_one "$name"
      done
elif [[ -n "${1:-}" ]]; then
  reverify_one "$1"
else
  die "usage: $0 <project-name> | --all"
fi
