#!/usr/bin/env bash
# similarity-check.sh <name-or-url-or-keyword>
#
# Quick scan of registry.md + projects/*/plan.md for projects covering similar
# ground to the target. Output: a ranked list of "might-overlap" projects with
# one-line context and a pointer.
#
# Used by coordinator as the first step of any new install — so we don't
# install Mem0 next to GBrain without noticing.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

query="${1:-}"
[[ -n "$query" ]] || { echo "usage: $0 <name-or-url-or-keyword>"; exit 1; }

# Normalize: strip URL prefixes, take last path component
normalized="$(echo "$query" | sed -E 's#https?://(www\.)?(github\.com/)?##' | awk -F/ '{print $NF}' | tr -d '/')"

echo "▶ Similarity check for: $query"
echo "  (normalized: $normalized)"
echo

# 1. Exact match in registry
if grep -qi "| $normalized " registry.md 2>/dev/null; then
  echo "◉ EXACT MATCH: already in registry.md"
  grep -i "| $normalized " registry.md
  echo
fi

# 2. Category overlap (match on category column)
echo "─── Category overlap ───"
# Build a search index from registry + plan files
{
  grep -h "^| " registry.md 2>/dev/null | awk -F'|' '{print $3"|"$5"|"$6}'
} | while IFS='|' read -r name category rest; do
    name_trim=$(echo "$name" | tr -d ' ')
    [[ -z "$name_trim" || "$name_trim" == "Project" ]] && continue

    # Rough keyword overlap
    keywords=$(echo "$normalized $category" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9 ' ' ')
    score=0
    for w in $(echo "$normalized" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' ' '); do
      [[ ${#w} -lt 3 ]] && continue
      if echo "$keywords" | grep -qw "$w"; then
        score=$((score+1))
      fi
    done
    if (( score > 0 )); then
      echo "  match=$score: $name_trim ($category)"
    fi
  done

# 3. Free-text scan of plan.md files (substring hit)
echo
echo "─── Plan.md substring hits ───"
if [[ -d projects ]]; then
  found=0
  for plan in projects/*/plan.md; do
    [[ -f "$plan" ]] || continue
    # Case-insensitive search for normalized query
    if grep -qi "$normalized" "$plan"; then
      lines=$(grep -i -c "$normalized" "$plan")
      echo "  $plan ($lines mentions)"
      grep -i "$normalized" "$plan" | head -2 | sed 's/^/    > /'
      found=$((found+1))
    fi
  done
  (( found == 0 )) && echo "  (no substring hits)"
fi

echo
echo "─── Verdict ───"
echo "If any of the above looks like the same job, ask the user before installing."
