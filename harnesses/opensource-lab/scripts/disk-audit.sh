#!/usr/bin/env bash
# disk-audit.sh
#
# Disk footprint across all lab projects (code + global state dirs).
# Writes .harness/reports/audit-<YYYYMMDD>.md and TSV.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

stamp="$(date -u +%Y%m%d)"
report=".harness/reports/audit-$stamp.md"
tsv=".harness/audit-$stamp.tsv"
mkdir -p .harness/reports

printf 'project\tcode_size\tstate_size\tstate_path\n' > "$tsv"

{
  echo "# Lab Disk Audit"
  echo
  echo "_Date: $(date -u +%Y-%m-%d)_"
  echo
  echo "## Per-project footprint"
  echo
  printf '| Project | Code | State (global) | State path |\n'
  printf '|---------|------|----------------|-----------|\n'

  for dir in projects/*/; do
    name=$(basename "$dir")
    [[ "$name" == "_archive" || "$name" == "_scouting" ]] && continue
    code_size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
    state_size="-"
    state_path="-"
    if [[ -d "$HOME/.$name" ]]; then
      state_size=$(du -sh "$HOME/.$name" 2>/dev/null | awk '{print $1}')
      state_path="~/.${name}/"
    fi
    printf '| %s | %s | %s | %s |\n' "$name" "$code_size" "$state_size" "$state_path"
    printf '%s\t%s\t%s\t%s\n' "$name" "$code_size" "$state_size" "$state_path" >> "$tsv"
  done

  echo
  echo "## Archive"
  if [[ -d projects/_archive ]]; then
    for dir in projects/_archive/*/; do
      [[ -d "$dir" ]] || continue
      name=$(basename "$dir")
      size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
      printf '- %s: %s\n' "$name" "$size"
    done
  fi

  echo
  echo "## Lab totals"
  echo
  echo "- projects/: $(du -sh projects 2>/dev/null | awk '{print $1}')"
  echo "- .harness/: $(du -sh .harness 2>/dev/null | awk '{print $1}')"
  echo
  echo "## Flags"
  awk -F'\t' 'NR>1 {
    code=$2; state=$3;
    # crude size parser: GB > 1 = flag
    if (code ~ /G$/ || state ~ /G$/) print "- ⚠ " $1 " is large (code="code", state="state")"
  }' "$tsv"
} > "$report"

echo "✓ $report"
echo "✓ $tsv"
