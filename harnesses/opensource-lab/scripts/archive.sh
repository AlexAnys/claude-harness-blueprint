#!/usr/bin/env bash
# archive.sh <project-name>
#
# Move projects/<name>/ to projects/_archive/<name>/, record archive timestamp.
# Non-destructive: nothing is deleted. The registry row is preserved but marked.
#
# Safety checks:
# - Lifecycle must be `deprecated` before archive (curator promotes first)
# - Prompts before moving (unless --force)
# - Records the move in .harness/progress.tsv

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

die() { echo "✗ $*" >&2; exit 1; }

name="${1:-}"
force="${2:-}"
[[ -n "$name" ]] || die "usage: $0 <project-name> [--force]"
src="projects/$name"
dst="projects/_archive/$name"

[[ -d "$src" ]] || die "no such project: $src"
[[ -d "$dst" ]] && die "already archived: $dst exists"

# Safety: check lifecycle (col 6 — Lifecycle)
lifecycle="$(awk -F'|' -v n="$name" '
  NR>1 {p=$3; gsub(/^ +| +$/,"",p); if (p==n) {lc=$6; gsub(/^ +| +$/,"",lc); print lc; exit}}' registry.md 2>/dev/null)"
if [[ "$lifecycle" != "deprecated" && "$force" != "--force" ]]; then
  echo "⚠ project '$name' lifecycle is '$lifecycle', not 'deprecated'."
  echo "  Promote it first (curator) or pass --force to override."
  exit 1
fi

if [[ "$force" != "--force" ]]; then
  read -rp "Move $src → $dst? [y/N] " confirm
  [[ "$confirm" =~ ^[yY]$ ]] || { echo "aborted"; exit 1; }
fi

mkdir -p projects/_archive
mv "$src" "$dst"

# Write archive stamp
stamp="projects/_archive/$name/ARCHIVED.md"
{
  echo "# $name — Archived"
  echo
  echo "_Archived: $(date -u +%Y-%m-%d)_"
  echo
  echo "## Reason"
  echo "(fill in — user-supplied reason for deprecation)"
  echo
  echo "## State at archive time"
  echo "- Disk size: $(du -sh "$dst" | awk '{print $1}')"
  echo "- Last registry row: $(grep "^| " registry.md | grep " $name " | head -1 || echo 'not found')"
  echo
  echo "## Restore procedure"
  echo "1. \`mv projects/_archive/$name projects/$name\`"
  echo "2. Run \`scripts/reverify.sh $name\` to check if it still works"
  echo "3. Update registry.md lifecycle back to \`installed\`"
} > "$stamp"

# Append to progress.tsv
printf '%s\t%s\tarchive\tcompleted\tmoved to projects/_archive/%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M)" "$name" "$name" >> .harness/progress.tsv

echo "✓ Archived $name → $dst"
echo "  Stamp written to $stamp"
echo "  Don't forget: update registry.md lifecycle → 'archived'"
