#!/usr/bin/env bash
# mac_memory.sh - READ-ONLY memory check for the Mac. It only reads numbers and prints them; it never
# kills, signals, quits or changes any process or setting. --watch also posts a macOS notification.
#   Swap used: RAM that spilled to disk; over 2 GB the Mac freezes. Pressure: the kernel level (normal,
#     warn, critical) plus the free percentage; not normal means macOS is compressing and swapping hard.
#   Top apps: resident memory (RSS) per app, all its processes summed, with the share of physical RAM.
#   RobloxStudio: process count. Each is several GB; keep one (a 2-player test adds one per client).
#   WARN: one line, printed when swap used > 2 GB, pressure is not normal, or > 1 RobloxStudio runs.
# Usage: tools/mac_memory.sh [--watch] [--every SECONDS] [--help]
export LC_ALL=C
set -u
EVERY=300; WATCH=0; SWAP_LIMIT_MB=2048; REPOST=1800
usage() {
  cat <<'EOF'
Usage: tools/mac_memory.sh [--watch] [--every SECONDS] [--help]
  (no option)  print memory, swap, pressure, the top 12 apps and the Studio count once
  --watch      repeat every 300 s; a WARN posts a notification (the same warning at most once per 30 min)
  --every N    seconds between checks, 10 or more (implies --watch). Read-only: kills nothing.
EOF
}
add_warn() { WARN="${WARN:+$WARN; }$2"; KEY="$KEY$1,"; }

report() {
  WARN=""; KEY=""
  local mem swap swap_mb mp pg
  mem=$(sysctl -n hw.memsize 2>/dev/null); mem=${mem:-0}
  echo "== Mac memory $(date '+%Y-%m-%d %H:%M:%S') =="
  awk -v b="$mem" 'BEGIN { printf "Physical memory: %.1f GB\n", b / 1073741824 }'
  swap=$(sysctl -n vm.swapusage 2>/dev/null)
  swap_mb=$(echo "$swap" | awk '{ for (i = 1; i < NF; i++) if ($i == "used") { v = $(i + 2); u = substr(v, length(v));
    n = substr(v, 1, length(v) - 1) + 0; if (u == "G") n *= 1024; else if (u == "K") n /= 1024; printf "%d", n } }')
  swap_mb=${swap_mb:-0}
  echo "Swap: ${swap:-unavailable}"
  LEVEL=""
  if command -v memory_pressure >/dev/null 2>&1; then
    mp=$(memory_pressure 2>/dev/null)
    echo "$mp" | grep 'System-wide memory free percentage' | tail -1
    LEVEL=$(echo "$mp" | grep -Eio 'normal|warn|critical' | head -1 | tr 'A-Z' 'a-z')
  else
    pg=$(vm_stat 2>/dev/null | awk '/page size of/ { for (i = 1; i <= NF; i++) if ($i == "of") ps = $(i + 1) }
      /^Pages free/ { f = $3 + 0 } END { printf "%d pages free (%.0f MB)", f, f * ps / 1048576 }')
    echo "memory_pressure not found; vm_stat: $pg"
  fi
  # the kernel's own level (1 normal, 2 warn, 4 critical) fills a missing level and wins when it says warn or critical
  case $(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null) in 1) LEVEL=${LEVEL:-normal};; 2) LEVEL=warn;; 4) LEVEL=critical;; esac
  echo "Pressure level: ${LEVEL:-unknown}"
  PROCS=$(ps -axo rss=,comm= 2>/dev/null)
  echo "Top 12 apps by resident memory (processes of one app summed):"
  echo "$PROCS" | awk '{ r = $1; sub(/^ *[0-9]+ +/, ""); sub(/\.app\/.*/, ""); sub(/^.*\//, "");
      if ($0 != "") k[$0] += r } END { for (a in k) printf "%d\t%s\n", k[a], a }' | sort -rn | head -12 |
    awk -F'\t' -v mem="$mem" '{ printf "%8.0f MB  %5.1f%%  %s\n", $1 / 1024, (mem > 0 ? $1 * 1024 * 100 / mem : 0), $2 }'
  STUDIO=$(echo "$PROCS" | awk '{ sub(/^ *[0-9]+ +/, ""); n = split($0, p, "/"); if (tolower(p[n]) == "robloxstudio") c++ } END { print c + 0 }')
  echo "RobloxStudio processes: $STUDIO"
  [ "$swap_mb" -gt "$SWAP_LIMIT_MB" ] && add_warn swap "swap used $(awk -v m="$swap_mb" 'BEGIN { printf "%.1f", m / 1024 }') GB (over $((SWAP_LIMIT_MB / 1024)) GB)"
  if [ -n "$LEVEL" ] && [ "$LEVEL" != normal ]; then add_warn pressure "memory pressure is $LEVEL"; fi
  if [ "$STUDIO" -gt 1 ]; then add_warn studio "$STUDIO RobloxStudio processes (keep one)"; fi
  if [ -n "$WARN" ]; then echo "WARN: $WARN"; else echo "OK: no warnings"; fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0;;
    --watch) WATCH=1;;
    --every) shift
      case "${1:-}" in ''|*[!0-9]*|?|0?) echo "--every needs whole seconds, 10 or more" >&2; exit 2;; esac
      EVERY=$1; WATCH=1;;
    *) usage >&2; exit 2;;
  esac
  shift
done

if [ "$WATCH" -eq 0 ]; then report; exit 0; fi
trap 'echo; echo "mac_memory: watch stopped"; exit 0' INT TERM
LAST_KEY=""; LAST_AT=0  # a changed set of reasons posts at once; the same set waits REPOST seconds
while :; do
  report
  if [ -n "$WARN" ]; then
    NOW=$(date +%s)
    if [ "$KEY" != "$LAST_KEY" ] || [ $((NOW - LAST_AT)) -ge "$REPOST" ]; then
      TXT=$(printf '%s' "$WARN" | tr -d '"\\')
      osascript -e 'display notification "'"$TXT"'" with title "Mac memory"' >/dev/null 2>&1
      LAST_KEY=$KEY; LAST_AT=$NOW
    fi
  fi
  sleep "$EVERY"
done
