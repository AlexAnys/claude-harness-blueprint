#!/usr/bin/env bash
# Stop hook — lab hygiene QA gate.
#
# Fires after every Claude Code response. Purpose: catch the kinds of drift that
# silently accumulate when many projects share a lab — unregistered projects,
# stale lifecycle, uncommitted registry changes, port collisions, missing
# setup-log. Non-fatal: prints warnings so Claude sees them next turn.
#
# Design rules:
#   - Fast (must finish in <2s across ~50 projects)
#   - Never blocks — only warns
#   - No network; no secrets; read-only
#   - Output lines starting with "::lab-gate::" are visible to Claude next turn

set -u
cd "$(dirname "$0")/../.." || exit 0   # lab root

warn() { printf '::lab-gate::WARN %s\n' "$*" >&2; }
info() { printf '::lab-gate::INFO %s\n' "$*" >&2; }

# 1. Every project in projects/ (non-archive) must appear in registry.md
if [[ -d projects ]] && [[ -f registry.md ]]; then
  for dir in projects/*/; do
    name=$(basename "$dir")
    [[ "$name" == "_archive" ]] && continue
    if ! grep -q "| $name " registry.md 2>/dev/null && ! grep -qi "| ${name} " registry.md 2>/dev/null; then
      warn "project '$name' not in registry.md"
    fi
  done
fi

# 2. Every project must have plan.md (minimal requirement)
if [[ -d projects ]]; then
  for dir in projects/*/; do
    name=$(basename "$dir")
    [[ "$name" == "_archive" ]] && continue
    [[ ! -f "$dir/plan.md" ]] && warn "project '$name' missing plan.md"
  done
fi

# 3. Installed / adopted projects must have setup-log.md
# Registry columns: | # | Project | Repo | Category | Lifecycle | Installed | Last verified | ...
# Lifecycle is $6 after split by |. Only warn when $6 ∈ {installed, adopted}.
if [[ -f registry.md ]]; then
  awk -F'|' '
    NR>1 && NF>=7 {
      name=$3; lc=$6
      gsub(/^ +| +$/,"",name); gsub(/^ +| +$/,"",lc)
      if (lc=="installed" || lc=="adopted") print name
    }' registry.md \
  | while read -r name; do
      [[ -z "$name" ]] && continue
      [[ -d "projects/$name" ]] || continue
      [[ ! -f "projects/$name/setup-log.md" ]] && warn "$name (lifecycle=installed/adopted) missing setup-log.md"
    done
fi

# 4. progress.tsv must exist and have header
if [[ ! -f .harness/progress.tsv ]]; then
  warn ".harness/progress.tsv is missing — create it"
elif ! head -1 .harness/progress.tsv | grep -q "^timestamp"; then
  warn ".harness/progress.tsv has wrong header (expected to start with 'timestamp')"
fi

# 5. Port collisions — same port claimed by >1 project
if [[ -f .harness/ports.tsv ]]; then
  dupes=$(tail -n +2 .harness/ports.tsv | awk -F'\t' 'NF>=2 && $2!="" {print $2}' | sort | uniq -d)
  if [[ -n "$dupes" ]]; then
    warn "port collision(s) in .harness/ports.tsv: $dupes"
  fi
fi

# 6b. Team persistence — silent-failure detector for the 2026-04-22 bug class.
# If lab activity exists (any project plan.md) but the persistent team has not been
# created, the coordinator is running as a short-lived subagent and will die at the
# first user-approval checkpoint. See CLAUDE.md "Bootstrap Protocol" + post-mortem.
team_config="$HOME/.claude/teams/lab/config.json"
if [[ -d projects ]] && compgen -G "projects/*/plan.md" >/dev/null 2>&1; then
  if [[ ! -f "$team_config" ]]; then
    warn "lab plan.md files exist but ~/.claude/teams/lab/ is MISSING — coordinator is likely a short-lived subagent (silent-failure mode). Run TeamCreate('lab') ASAP. See CLAUDE.md Bootstrap Protocol."
  else
    # Team exists — sanity check it has the 3 required members
    if command -v jq >/dev/null 2>&1; then
      missing=$(jq -r '["coordinator","executor","qa"] - [.members[].name] | join(",")' "$team_config" 2>/dev/null)
      if [[ -n "$missing" && "$missing" != "" ]]; then
        warn "team 'lab' exists but missing required members: $missing"
      fi
    fi
  fi
fi

# 7. Stale installs — no reverify in >90 days (warning only)
# Columns: $3=name, $6=lifecycle, $8=last_verified
today_epoch=$(date -u +%s)
stale_days=90
if [[ -f registry.md ]]; then
  awk -F'|' '
    NR>1 && NF>=8 {
      name=$3; lc=$6; lv=$8
      gsub(/^ +| +$/,"",name); gsub(/^ +| +$/,"",lc); gsub(/^ +| +$/,"",lv)
      if ((lc=="installed" || lc=="adopted") && lv ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) print lv, name
    }' registry.md \
  | while read -r date_str name; do
      if ts=$(date -j -f "%Y-%m-%d" "$date_str" +%s 2>/dev/null); then
        age_days=$(( (today_epoch - ts) / 86400 ))
        if (( age_days > stale_days )); then
          info "'$name' last verified ${age_days}d ago — consider scripts/reverify.sh"
        fi
      fi
    done
fi

exit 0
