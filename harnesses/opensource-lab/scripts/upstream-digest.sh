#!/usr/bin/env bash
# upstream-digest.sh
#
# For every installed/adopted project, check GitHub releases since last_verified.
# Write .harness/reports/upstream-digest-<YYYYMMDD>.md.
#
# Requires: gh CLI authenticated (`gh auth status`).
# Read-only; no installs, no config changes.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

command -v gh >/dev/null 2>&1 || { echo "✗ gh CLI missing — brew install gh"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "✗ gh not authenticated — run 'gh auth login'"; exit 1; }

stamp="$(date -u +%Y%m%d)"
report=".harness/reports/upstream-digest-$stamp.md"
mkdir -p .harness/reports

{
  echo "# Upstream Digest"
  echo
  echo "_Date: $(date -u +%Y-%m-%d) • Source: GitHub releases API_"
  echo

  # Registry cols: | # | Project(3) | Repo(4) | Category(5) | Lifecycle(6) | Installed(7) | Last verified(8) | ...
  awk -F'|' '
    NR>1 && NF>=8 {
      name=$3; repo=$4; lc=$6; lv=$8
      gsub(/^ +| +$/,"",name); gsub(/^ +| +$/,"",repo)
      gsub(/^ +| +$/,"",lc); gsub(/^ +| +$/,"",lv)
      if (lc=="installed" || lc=="adopted") print name"\t"repo"\t"lv
    }' registry.md \
    | while IFS=$'\t' read -r name repo last_verified; do
        [[ -z "$name" || -z "$repo" ]] && continue

        echo "## $name ($repo)"
        echo "_Last verified: $last_verified_"
        echo

        # Get releases since last_verified
        releases=$(gh api "repos/$repo/releases?per_page=20" 2>/dev/null || echo "[]")
        if [[ "$releases" == "[]" || -z "$releases" ]]; then
          echo "_No releases API data (repo may not use GitHub releases)._"
          echo
          continue
        fi

        new=$(echo "$releases" | python3 -c "
import sys, json
try:
    rels = json.load(sys.stdin)
    lv = '$last_verified' + 'T00:00:00Z'
    for r in rels:
        if r.get('published_at','') > lv:
            title = r.get('tag_name') or r.get('name') or '?'
            date = r.get('published_at','')[:10]
            url = r.get('html_url','')
            print(f'- **{title}** ({date}) — {url}')
except Exception as e:
    print(f'_parse error: {e}_')
")

        if [[ -z "$new" ]]; then
          echo "_No new releases since $last_verified._"
        else
          echo "$new"
        fi
        echo
      done

  echo "---"
  echo "_Next step: for any release marked **breaking** or major, consider re-verify._"
} > "$report"

echo "✓ $report"
