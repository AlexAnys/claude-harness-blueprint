#!/usr/bin/env bash
# port-registry.sh
#
# Utility: inspect / allocate ports for lab projects.
#
#   scripts/port-registry.sh list             — show all claimed ports
#   scripts/port-registry.sh next             — print next free port in 8080-8999
#   scripts/port-registry.sh claim <name> <port> <proto> <purpose>
#   scripts/port-registry.sh check            — detect collisions

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1
F=".harness/ports.tsv"

[[ -f "$F" ]] || {
  echo "creating $F"
  printf 'project\tport\tprotocol\tpurpose\tclaimed\n' > "$F"
}

cmd="${1:-list}"

case "$cmd" in
  list)
    column -s$'\t' -t < "$F"
    ;;
  next)
    used=$(awk -F'\t' 'NR>1 {print $2}' "$F" | sort -n)
    for p in $(seq 8080 8999); do
      if ! echo "$used" | grep -qw "$p"; then
        echo "$p"; exit 0
      fi
    done
    echo "✗ no free port in 8080-8999"; exit 1
    ;;
  claim)
    name="${2:?name required}"
    port="${3:?port required}"
    proto="${4:-http}"
    purpose="${5:-unspecified}"
    if awk -F'\t' -v p="$port" '$2==p {exit 1}' "$F"; then
      printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$port" "$proto" "$purpose" "$(date -u +%Y-%m-%d)" >> "$F"
      echo "✓ claimed $port for $name"
    else
      echo "✗ port $port already claimed:"
      awk -F'\t' -v p="$port" '$2==p' "$F"
      exit 1
    fi
    ;;
  check)
    dupes=$(tail -n +2 "$F" | awk -F'\t' '{print $2}' | sort | uniq -d)
    if [[ -n "$dupes" ]]; then
      echo "✗ port collision(s):"
      for d in $dupes; do
        awk -F'\t' -v p="$d" '$2==p' "$F"
      done
      exit 1
    fi
    echo "✓ no collisions"
    ;;
  *)
    echo "usage: $0 {list|next|claim <name> <port> [proto] [purpose]|check}"
    exit 1
    ;;
esac
